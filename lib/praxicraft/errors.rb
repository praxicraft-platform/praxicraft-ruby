# frozen_string_literal: true

module Praxicraft
  class Error < StandardError
    attr_reader :error_code

    def initialize(message, error_code = nil)
      super(message)
      @error_code = error_code
    end

    alias code error_code
  end

  class APIError < Error; end

  class APIConnectionError < APIError
    def initialize(message = "Failed to connect to the Praxicraft API.")
      super(message, "CONNECTION_ERROR")
    end
  end

  class APIStatusError < APIError
    attr_reader :status_code, :details, :response_body, :headers, :required_plan, :retry_after

    def initialize(
      message,
      status_code:,
      error_code: nil,
      details: nil,
      response_body: nil,
      headers: {},
      required_plan: nil,
      retry_after: nil
    )
      super(message, error_code)
      @status_code = status_code
      @details = details
      @response_body = response_body
      @headers = headers || {}
      @required_plan = required_plan
      @retry_after = retry_after
    end
  end

  class AuthenticationError < APIStatusError; end
  class InsufficientScopeError < APIStatusError; end
  class NotFoundError < APIStatusError; end
  class ValidationError < APIStatusError; end
  class RateLimitError < APIStatusError; end
end
