# frozen_string_literal: true

module Praxicraft
  module Resources
    class Invites
      def initialize(client)
        @client = client
      end

      def list(params = nil)
        @client.get("/invites/", normalize(params))
      end

      def retrieve(invite_token)
        token = Client.path_segment(invite_token, "invite_token")
        @client.get("/invites/#{token}/")
      end

      def create(assessment, args = nil, **kwargs)
        body = normalize(args || kwargs) || {}
        email = body["email"]
        if email.nil? || email.to_s.strip.empty?
          raise APIError.new("email is required", "INVALID_ARGUMENT")
        end

        key = Client.path_segment(assessment, "assessment")
        @client.post("/assessments/#{key}/invites/", body)
      end

      def bulk_create(assessment, candidates, args = nil, **kwargs)
        key = Client.path_segment(assessment, "assessment")
        body = { "candidates" => candidates }.merge(normalize(args || kwargs) || {})
        @client.post("/assessments/#{key}/invites/bulk/", body)
      end

      def remind(invite_token)
        token = Client.path_segment(invite_token, "invite_token")
        @client.post("/invites/#{token}/remind/")
      end

      def cancel(invite_token)
        token = Client.path_segment(invite_token, "invite_token")
        @client.delete("/invites/#{token}/")
      end

      private

      def normalize(hash)
        return nil if hash.nil?

        hash.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
      end
    end
  end
end
