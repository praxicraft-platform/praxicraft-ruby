# frozen_string_literal: true

module Praxicraft
  module Resources
    class Webhooks
      def initialize(client)
        @client = client
      end

      def list(params = nil)
        @client.get("/webhooks/", normalize(params))
      end

      def create(args = nil, **kwargs)
        body = normalize(args || kwargs) || {}
        url = body["url"]
        events = body["events"]
        if url.nil? || url.to_s.strip.empty?
          raise APIError.new("url is required", "INVALID_ARGUMENT")
        end
        if !events.is_a?(Array) || events.empty?
          raise APIError.new("events must be a non-empty list", "INVALID_ARGUMENT")
        end

        @client.post("/webhooks/create/", body)
      end

      def retrieve(webhook_id)
        key = Client.path_segment(webhook_id, "webhook_id")
        @client.get("/webhooks/#{key}/")
      end

      def update(webhook_id, fields = nil, **kwargs)
        body = normalize(fields || kwargs)
        if body.nil? || body.empty?
          raise APIError.new("update() requires at least one field to change", "INVALID_ARGUMENT")
        end

        key = Client.path_segment(webhook_id, "webhook_id")
        @client.patch("/webhooks/#{key}/", body)
      end

      def delete(webhook_id)
        key = Client.path_segment(webhook_id, "webhook_id")
        @client.delete("/webhooks/#{key}/")
      end

      def deliveries(webhook_id)
        key = Client.path_segment(webhook_id, "webhook_id")
        @client.get("/webhooks/#{key}/deliveries/")
      end

      def test(webhook_id)
        key = Client.path_segment(webhook_id, "webhook_id")
        @client.post("/webhooks/#{key}/test/")
      end

      private

      def normalize(hash)
        return nil if hash.nil?

        hash.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
      end
    end
  end
end
