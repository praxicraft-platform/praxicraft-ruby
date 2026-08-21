# frozen_string_literal: true

require "openssl"

module Praxicraft
  module Webhooks
    module_function

    # Verify an X-Praxicraft-Signature header (sha256=<hex> or legacy bare hex).
    # +body+ may be nil (treated as empty payload).
    def verify_signature(secret, body, header_sig)
      return false if secret.nil? || secret.empty? || header_sig.nil? || header_sig.empty?

      payload = body.nil? ? "" : body.to_s
      digest = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
      expected = "sha256=#{digest}"

      if header_sig.start_with?("sha256=")
        secure_compare(expected, header_sig)
      else
        secure_compare(digest, header_sig) || secure_compare(expected, header_sig)
      end
    end

    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      OpenSSL.fixed_length_secure_compare(a, b)
    rescue StandardError
      false
    end
    private_class_method :secure_compare
  end
end
