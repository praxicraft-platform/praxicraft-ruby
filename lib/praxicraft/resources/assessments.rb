# frozen_string_literal: true

module Praxicraft
  module Resources
    class Assessments
      def initialize(client)
        @client = client
      end

      def list(params = nil)
        @client.get("/assessments/", normalize(params))
      end

      def retrieve(assessment)
        key = Client.path_segment(assessment, "assessment")
        @client.get("/assessments/#{key}/")
      end

      def create(fields = nil, **kwargs)
        body = normalize(fields || kwargs)
        @client.post("/assessments/create/", body)
      end

      def update(assessment, fields = nil, **kwargs)
        body = normalize(fields || kwargs)
        if body.nil? || body.empty?
          raise APIError.new("update() requires at least one field to change", "INVALID_ARGUMENT")
        end

        key = Client.path_segment(assessment, "assessment")
        @client.patch("/assessments/#{key}/update/", body)
      end

      def activate(assessment)
        update(assessment, "status" => "active")
      end

      def list_tasks(assessment, params = nil)
        key = Client.path_segment(assessment, "assessment")
        @client.get("/assessments/#{key}/tasks/", normalize(params))
      end

      def attach_tasks(assessment, args = nil, **kwargs)
        body = normalize(args || kwargs)
        if body.nil? || body.empty?
          raise APIError.new("attach_tasks() requires tasks or task_id", "INVALID_ARGUMENT")
        end

        key = Client.path_segment(assessment, "assessment")
        @client.post("/assessments/#{key}/tasks/attach/", body)
      end

      def replace_tasks(assessment, tasks, extra = nil, **kwargs)
        key = Client.path_segment(assessment, "assessment")
        body = { "tasks" => tasks }.merge(normalize(extra || kwargs) || {})
        @client.put("/assessments/#{key}/tasks/replace/", body)
      end

      def remove_task(assessment, assessment_task_id)
        key = Client.path_segment(assessment, "assessment")
        task_id = assessment_task_id.to_s.strip
        if task_id.empty?
          raise APIError.new("assessment_task_id must be a non-empty string", "INVALID_ARGUMENT")
        end

        @client.delete("/assessments/#{key}/tasks/remove/", { "assessment_task_id" => task_id })
      end

      private

      def normalize(hash)
        return nil if hash.nil?

        hash.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
      end
    end
  end
end
