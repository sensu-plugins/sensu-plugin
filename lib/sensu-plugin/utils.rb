require 'json'

module Sensu
  module Plugin
    module Utils # rubocop:disable Metrics/ModuleLength
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

      # Override API settings (for testing purposes)
      #
      # @param api_settings [Hash]
      # @return [Hash]
      def api_settings=(api_settings)
        @api_settings = api_settings
      end

      # Return a hash of API settings derived first from ENV['SENSU_API_URL'] if set,
      # then Sensu config `api` scope if configured, and finally falling back to
      # to ipv4 localhost address on default API port.
      #
      # @return [Hash]
      def api_settings
        return @api_settings if @api_settings
        if ENV['SENSU_API_URL']
          uri = URI(ENV['SENSU_API_URL'])
          ssl = uri.scheme == 'https' ? {} : nil
          @api_settings = {
            'ssl' => ssl,
            'host' => uri.host,
            'port' => uri.port,
            'user' => uri.user,
            'password' => uri.password
          }
        else
          @api_settings = settings['api'] || {}
          @api_settings['host'] ||= '127.0.0.1'
          @api_settings['port'] ||= 4567
        end
        @api_settings
      end

      def api_request(method, path, &_blk)
        if api_settings.nil?
          raise 'api.json settings not found.'
        end
        use_ssl = api_settings['ssl'].is_a?(Hash) ||
                  api_settings['host'].start_with?('https')
        hostname = api_settings['host'].gsub(/https?:\/\//, '')
        req = net_http_req_class(method).new(path)
        if api_settings['user'] && api_settings['password']
          req.basic_auth(api_settings['user'], api_settings['password'])
        end
        yield(req) if block_given?
        res = Net::HTTP.start(hostname, api_settings['port'], use_ssl: use_ssl) do |http|
          http.request(req)
        end
        res
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
          # when the data is empty, we have hit the end
          break if data.empty?
          # If API lacks pagination support, it will
          # return same data on subsequent iterations
          break if results.any? { |r| r == data }
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
