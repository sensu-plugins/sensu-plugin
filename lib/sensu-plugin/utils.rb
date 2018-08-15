require 'json'

module Sensu
  module Plugin
    module Utils
      def config_files
        if ENV['SENSU_LOADED_TEMPFILE'] && File.file?(ENV['SENSU_LOADED_TEMPFILE'])
          IO.read(ENV['SENSU_LOADED_TEMPFILE']).split(':')
        elsif ENV['SENSU_CONFIG_FILES']
          ENV['SENSU_CONFIG_FILES'].split(':')
        else
          ['/etc/sensu/config.json'] + Dir['/etc/sensu/conf.d/**/*.json']
        end
      end

      def load_config(filename)
        JSON.parse(File.open(filename, 'r').read)
      rescue
        {}
      end

      def settings
        @settings ||= config_files.map { |f| load_config(f) }.reduce { |a, b| deep_merge(a, b) }
      end

      def read_event(file)
        @event = ::JSON.parse(file.read)
        @event['occurrences'] ||= 1
        @event['check']       ||= {}
        @event['client']      ||= {}
      rescue => e
        puts 'error reading event: ' + e.message
        exit 0
      end

      def net_http_req_class(method)
        case method.to_s.upcase
        when 'GET'
          Net::HTTP::Get
        when 'POST'
          Net::HTTP::Post
        when 'DELETE'
          Net::HTTP::Delete
        when 'PUT'
          Net::HTTP::Put
        end
      end

      # Use API query parameters to paginate HTTP GET requests,
      # iterating over the results until an empty set is returned.
      #
      # @param path [String]
      # @param options [Hash]
      # @return [Array]

      def paginated_get(path, options = {})
        limit = options.fetch('limit', 500)
        offset = 0
        results = []
        loop do
          query_path = "#{path}?limit=#{limit}&offset=#{offset}"
          response = api_request(:GET, query_path)
          unless response.is_a?(Net::HTTPOK)
            unknown("Non-OK response from API query: #{get_uri(query_path)}")
          end
          data = JSON.parse(response.body)
          break if data.empty?
          results << data
          offset += limit
        end
        results.flatten
      end

      def deep_merge(hash_one, hash_two)
        merged = hash_one.dup
        hash_two.each do |key, value|
          merged[key] = if hash_one[key].is_a?(Hash) && value.is_a?(Hash)
                          deep_merge(hash_one[key], value)
                        elsif hash_one[key].is_a?(Array) && value.is_a?(Array)
                          hash_one[key].concat(value).uniq
                        else
                          value
                        end
        end
        merged
      end

      def cast_bool_values_int(value)
        case value
        when 'true', true
          1
        when 'false', false
          0
        else
          value
        end
      end
    end
  end
end
