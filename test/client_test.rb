# frozen_string_literal: true

require_relative "test_helper"

class ClientTest < Minitest::Test
  def test_org_retrieve_uses_mock_handler
    calls = []
    client = Praxicraft::Client.new(
      api_key: "ct_test_x",
      http_handler: lambda { |method, url, headers, body|
        calls << [method, url, headers, body]
        {
          status: 200,
          headers: { "content-type" => "application/json" },
          body: JSON.generate({ "name" => "Acme", "plan" => "starter" })
        }
      }
    )

    org = client.org.retrieve
    assert_equal "Acme", org["name"]
    assert_equal "GET", calls[0][0]
    assert_includes calls[0][1], "/api/v1/public/org/"
    assert_equal "Bearer ct_test_x", calls[0][2]["Authorization"]
    assert_match(%r{\Apraxicraft-ruby/}, calls[0][2]["User-Agent"])
  end

  def test_maps_authentication_error
    client = Praxicraft::Client.new(
      api_key: "ct_test_x",
      max_retries: 0,
      http_handler: lambda { |_m, _u, _h, _b|
        {
          status: 401,
          headers: {},
          body: JSON.generate({ "error" => { "code" => "INVALID_API_KEY", "message" => "bad" } })
        }
      }
    )

    err = assert_raises(Praxicraft::AuthenticationError) { client.org.retrieve }
    assert_equal "INVALID_API_KEY", err.code
    assert_equal 401, err.status_code
  end

  def test_assessments_create_path
    calls = []
    client = Praxicraft::Client.new(
      api_key: "ct_test_x",
      http_handler: lambda { |method, url, headers, body|
        calls << [method, url, headers, body]
        { status: 201, headers: {}, body: JSON.generate({ "slug" => "demo" }) }
      }
    )

    client.assessments.create("title" => "Demo")
    assert_equal "POST", calls[0][0]
    assert_includes calls[0][1], "/api/v1/public/assessments/create/"
  end

  def test_invites_create_path
    calls = []
    client = Praxicraft::Client.new(
      api_key: "ct_test_x",
      http_handler: lambda { |method, url, _h, body|
        calls << [method, url, body]
        { status: 200, headers: {}, body: JSON.generate({ "invite_token" => "tok" }) }
      }
    )

    client.invites.create("senior-backend-screen", email: "a@example.com")
    assert_equal "POST", calls[0][0]
    assert_includes calls[0][1], "/api/v1/public/assessments/senior-backend-screen/invites/"
  end

  def test_results_retrieve_path
    calls = []
    client = Praxicraft::Client.new(
      api_key: "ct_test_x",
      http_handler: lambda { |method, url, _h, _b|
        calls << [method, url]
        { status: 200, headers: {}, body: "{}" }
      }
    )

    client.results.retrieve("inv_abc")
    assert_equal "GET", calls[0][0]
    assert_includes calls[0][1], "/api/v1/public/invites/inv_abc/result/"
  end

  def test_missing_api_key
    old = ENV["PRAXICRAFT_API_KEY"]
    ENV.delete("PRAXICRAFT_API_KEY")
    err = assert_raises(Praxicraft::APIError) { Praxicraft::Client.new }
    assert_equal "MISSING_API_KEY", err.code
  ensure
    ENV["PRAXICRAFT_API_KEY"] = old if old
  end
end
