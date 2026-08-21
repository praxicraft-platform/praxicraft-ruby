# frozen_string_literal: true

require "uri"

module Praxicraft
  module Resources
    class Results
      MAX_RESULT_PAGES = 10_000

      def initialize(client)
        @client = client
      end

      # kwargs / hash: cursor, page_size, params
      def list(assessment, args = nil, **kwargs)
        opts = symbolize(args || kwargs)
        query = normalize(opts[:params] || {}) || {}
        query["cursor"] = opts[:cursor] if opts.key?(:cursor)
        query["page_size"] = opts[:page_size] if opts.key?(:page_size)

        key = Client.path_segment(assessment, "assessment")
        @client.get("/assessments/#{key}/results/", query)
      end

      def retrieve(invite_token)
        token = Client.path_segment(invite_token, "invite_token")
        @client.get("/invites/#{token}/result/")
      end

      def iter_all(assessment, args = nil, **kwargs, &block)
        opts = symbolize(args || kwargs)
        return enum_for(:iter_all, assessment, opts) unless block_given?

        cursor = nil
        seen = {}

        MAX_RESULT_PAGES.times do
          page_args = opts.dup
          page_args[:cursor] = cursor unless cursor.nil?
          page = list(assessment, page_args)
          return unless page.is_a?(Hash)

          results = page["results"] || page[:results]
          results.each(&block) if results.is_a?(Array)

          nxt = next_cursor(page)
          return if nxt.nil? || seen[nxt]

          seen[nxt] = true
          cursor = nxt
        end
      end

      private

      def symbolize(hash)
        return {} if hash.nil?

        hash.each_with_object({}) { |(k, v), acc| acc[k.to_sym] = v }
      end

      def normalize(hash)
        return nil if hash.nil?

        hash.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
      end

      def next_cursor(page)
        nc = page["next_cursor"] || page[:next_cursor]
        return nc if nc.is_a?(String) && !nc.empty?

        next_link = page["next"] || page[:next]
        return nil unless next_link.is_a?(String) && !next_link.empty?

        uri = URI.parse(next_link)
        return nil if uri.query.nil?

        q = URI.decode_www_form(uri.query).to_h
        c = q["cursor"]
        c.is_a?(String) && !c.empty? ? c : nil
      rescue URI::InvalidURIError
        nil
      end
    end
  end
end
