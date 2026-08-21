# frozen_string_literal: true

module Praxicraft
  module Resources
    class Pipelines
      def initialize(client)
        @client = client
      end

      def list(params = nil)
        @client.get("/pipelines/", normalize(params))
      end

      def retrieve(pipeline)
        key = Client.path_segment(pipeline, "pipeline")
        @client.get("/pipelines/#{key}/")
      end

      def enroll(pipeline, args = nil, **kwargs)
        body = normalize(args || kwargs) || {}
        email = body["email"]
        if email.nil? || email.to_s.strip.empty?
          raise APIError.new("email is required", "INVALID_ARGUMENT")
        end

        key = Client.path_segment(pipeline, "pipeline")
        @client.post("/pipelines/#{key}/enroll/", body)
      end

      def bulk_enroll(pipeline, candidates, args = nil, **kwargs)
        key = Client.path_segment(pipeline, "pipeline")
        body = { "candidates" => candidates }.merge(normalize(args || kwargs) || {})
        @client.post("/pipelines/#{key}/enroll/bulk/", body)
      end

      def list_enrollments(pipeline, params = nil)
        key = Client.path_segment(pipeline, "pipeline")
        @client.get("/pipelines/#{key}/enrollments/", normalize(params))
      end

      def get_enrollment(enrollment_id)
        key = Client.path_segment(enrollment_id, "enrollment_id")
        @client.get("/pipelines/enrollments/#{key}/")
      end

      private

      def normalize(hash)
        return nil if hash.nil?

        hash.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
      end
    end
  end
end
