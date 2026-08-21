# frozen_string_literal: true

require_relative "test_helper"
require "openssl"

class WebhooksTest < Minitest::Test
  def test_verify_signature_prefixed
    secret = "whsec_test"
    body = '{"ok":true}'
    digest = OpenSSL::HMAC.hexdigest("SHA256", secret, body)
    assert Praxicraft::Webhooks.verify_signature(secret, body, "sha256=#{digest}")
  end

  def test_verify_signature_legacy_hex
    secret = "whsec_test"
    body = '{"ok":true}'
    digest = OpenSSL::HMAC.hexdigest("SHA256", secret, body)
    assert Praxicraft::Webhooks.verify_signature(secret, body, digest)
  end

  def test_verify_signature_rejects_bad
    refute Praxicraft::Webhooks.verify_signature("whsec_test", "{}", "sha256=deadbeef")
  end

  def test_null_body_is_empty
    secret = "whsec_test"
    digest = OpenSSL::HMAC.hexdigest("SHA256", secret, "")
    assert Praxicraft::Webhooks.verify_signature(secret, nil, "sha256=#{digest}")
  end
end
