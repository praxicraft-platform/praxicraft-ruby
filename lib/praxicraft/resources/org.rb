# frozen_string_literal: true

module Praxicraft
  module Resources
    class Org
      def initialize(client)
        @client = client
      end

      def retrieve
        @client.get("/org/")
      end

      def stats(params = nil)
        @client.get("/org/stats/", normalize(params))
      end

      private

      def normalize(hash)
        return nil if hash.nil?

        hash.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
      end
    end
  end
end
