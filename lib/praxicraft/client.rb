# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require "time"
require "openssl"

module Praxicraft
  class Client
    DEFAULT_BASE_URL = "https://assess.praxicraft.com"
    DEFAULT_API_PREFIX = "/api/v1/public"
    DEFAULT_TIMEOUT_SECONDS = 30.0
    DEFAULT_MAX_RETRIES = 2

    attr_reader :api_key, :base_url, :api_prefix, :timeout_seconds, :max_retries
    attr_reader :org, :assessments, :invites, :results, :webhooks, :pipelines

    # Options keys: :api_key, :base_url, :timeout_seconds, :max_retries, :http_handler
    # http_handler: callable(method, url, headers, body) -> { status:, headers:, body: }
    def initialize(options = nil, **kwargs)
      opts = {}
      opts.merge!(options.transform_keys(&:to_sym)) if options.is_a?(Hash)
      opts.merge!(kwargs)

      key = (opts[:api_key] || ENV["PRAXICRAFT_API_KEY"] || "").to_s.strip
      if key.empty?
        raise APIError.new(
          "No API key provided. Pass api_key or set PRAXICRAFT_API_KEY.",
          "MISSING_API_KEY"
        )
      end

      base = (opts[:base_url] || ENV["PRAXICRAFT_API_BASE_URL"] || DEFAULT_BASE_URL).to_s.strip
      base = base.sub(%r{/*\z}, "")
      if base.empty?
        raise APIError.new("baseUrl must be a non-empty URL.", "INVALID_BASE_URL")
      end

      @api_key = key
      @base_url = base
      @api_prefix = DEFAULT_API_PREFIX
      @timeout_seconds = (opts[:timeout_seconds] || DEFAULT_TIMEOUT_SECONDS).to_f
      @max_retries = [0, (opts[:max_retries] || DEFAULT_MAX_RETRIES).to_i].max
      @http_handler = opts[:http_handler]

      @org = Resources::Org.new(self)
      @assessments = Resources::Assessments.new(self)
      @invites = Resources::Invites.new(self)
      @results = Resources::Results.new(self)
      @webhooks = Resources::Webhooks.new(self)
      @pipelines = Resources::Pipelines.new(self)
    end

    def get(path, params = nil)
      request("GET", path, params: params)
    end

    def post(path, json = nil)
      request("POST", path, json: json)
    end

    def put(path, json = nil)
      request("PUT", path, json: json)
    end

    def patch(path, json = nil)
      request("PATCH", path, json: json)
    end

    def delete(path, json = nil)
      request("DELETE", path, json: json)
    end

    def self.path_segment(value, label = "id")
      text = value.to_s.strip
      if text.empty?
        raise APIError.new("#{label} must be a non-empty string", "INVALID_PATH")
      end

      # Path-component encoding (spaces as %20), matching Node encodeURIComponent.
      URI.encode_www_form_component(text).gsub("+", "%20")
    end

    def path_segment(value, label = "id")
      self.class.path_segment(value, label)
    end

    def request(method, path, params: nil, json: nil)
      attempts = @max_retries + 1
      last_error = nil

      attempts.times do |attempt|
        if attempt.positive?
          retry_after = nil
          if last_error.is_a?(APIStatusError)
            retry_after = last_error.headers["retry-after"]
          end
          sleep(self.class.retry_delay_seconds(attempt - 1, retry_after))
        end

        begin
          return request_once(method, path, params: params, json: json)
        rescue APIConnectionError => e
          last_error = e
          next if attempt < attempts - 1

          raise
        rescue APIStatusError => e
          last_error = e
          next if self.class.should_retry_status?(e.status_code) && attempt < attempts - 1

          raise
        end
      end

      raise last_error || APIConnectionError.new
    end

    RETRY_BASE_SECONDS = 0.5
    RETRY_CAP_SECONDS = 8.0
    RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504].freeze

    def self.should_retry_status?(status)
      RETRYABLE_STATUS_CODES.include?(status)
    end

    def self.parse_retry_after_seconds(retry_after)
      return nil if retry_after.nil? || retry_after.to_s.strip.empty?

      text = retry_after.to_s.strip
      return [0.0, text.to_f].max if text.match?(/\A\d+(\.\d+)?\z/)

      begin
        when_time = Time.httpdate(text)
        [0.0, when_time - Time.now].max
      rescue ArgumentError
        nil
      end
    end

    def self.retry_delay_seconds(retry_index, retry_after)
      parsed = parse_retry_after_seconds(retry_after)
      return [parsed, RETRY_CAP_SECONDS].min unless parsed.nil?

      ceiling = [RETRY_CAP_SECONDS, RETRY_BASE_SECONDS * (2**retry_index)].min
      rand * ceiling
    end

    def self.raise_for_status(status_code, body, headers, raw)
      error = {}
      if body.is_a?(Hash) && body["error"].is_a?(Hash)
        error = body["error"]
      end

      code = error["code"].is_a?(String) ? error["code"] : nil
      message = error["message"].is_a?(String) ? error["message"] : nil
      details = error["details"]
      required_plan = error["required_plan"].is_a?(String) ? error["required_plan"] : nil

      if message.nil? || message.empty?
        trimmed = raw.to_s.strip
        message = trimmed.empty? ? "API request failed with status #{status_code}." : trimmed[0, 500]
      end

      retry_after = parse_retry_after_seconds(headers["retry-after"])

      kwargs = {
        status_code: status_code,
        error_code: code,
        details: details,
        response_body: body,
        headers: headers,
        required_plan: required_plan,
        retry_after: retry_after
      }

      raise AuthenticationError.new(message, **kwargs) if status_code == 401
      raise InsufficientScopeError.new(message, **kwargs) if status_code == 403
      raise NotFoundError.new(message, **kwargs) if status_code == 404
      raise RateLimitError.new(message, **kwargs) if status_code == 429
      raise ValidationError.new(message, **kwargs) if status_code >= 400 && status_code < 500

      raise APIStatusError.new(message, **kwargs)
    end

    private

    def request_once(method, path, params: nil, json: nil)
      url = "#{@base_url}#{@api_prefix}#{path}"
      if params && !params.empty?
        query = URI.encode_www_form(flatten_params(params))
        url = "#{url}#{url.include?('?') ? '&' : '?'}#{query}" unless query.empty?
      end

      headers = {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{@api_key}",
        "User-Agent" => "praxicraft-ruby/#{VERSION}"
      }

      body = nil
      unless json.nil?
        body = JSON.generate(json)
        headers["Content-Type"] = "application/json"
      end

      begin
        response = if @http_handler
                     @http_handler.call(method, url, headers, body)
                   else
                     net_http_request(method, url, headers, body)
                   end
      rescue APIConnectionError
        raise
      rescue StandardError => e
        raise APIConnectionError, e.message
      end

      status = response[:status] || response["status"]
      resp_headers = normalize_headers(response[:headers] || response["headers"] || {})
      raw = (response[:body] || response["body"] || "").to_s

      decoded = nil
      unless raw.empty?
        begin
          decoded = JSON.parse(raw)
        rescue JSON::ParserError
          if status.to_i >= 200 && status.to_i < 300
            raise APIError.new("Invalid JSON response (HTTP #{status}).", "INVALID_JSON")
          end
          decoded = raw
        end
      end

      return decoded if status.to_i >= 200 && status.to_i < 300

      self.class.raise_for_status(status.to_i, decoded, resp_headers, raw)
    end

    def net_http_request(method, url, headers, body)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout_seconds
      http.read_timeout = @timeout_seconds

      request = Net::HTTPGenericRequest.new(
        method.upcase,
        !body.nil?,
        true,
        uri.request_uri,
        headers
      )
      request.body = body unless body.nil?

      res = http.request(request)
      {
        status: res.code.to_i,
        headers: res.each_header.to_h,
        body: res.body.to_s
      }
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError, OpenSSL::SSL::SSLError => e
      raise APIConnectionError, e.message
    end

    def flatten_params(params)
      out = {}
      params.each do |k, v|
        next if v.nil?

        out[k.to_s] = if v == true
                        "true"
                      elsif v == false
                        "false"
                      else
                        v
                      end
      end
      out
    end

    def normalize_headers(headers)
      headers.each_with_object({}) do |(k, v), acc|
        acc[k.to_s.downcase] = v.to_s
      end
    end
  end
end
