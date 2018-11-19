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

      def event
        @event
      end

      def event=(value)
        @event = value
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

      ##
      #  Helper method to convert Sensu 2.0 event into Sensu 1.4 event
      #    This is here to help keep Sensu Plugin community handlers working
      #    until they natively support 2.0
      #    Takes 2.0 event json object as argument
      #    Returns event with 1.4 mapping included
      #
      #    Note:
      #      The 1.4 mapping overwrites some attributes so the resulting event cannot
      #      be used in a 2.0 workflow. The top level boolean attribute "v2_event_mapped_into_v1"
      #      will be set to true as a hint to indicate this is a mapped event object.
      #
      ##
      def map_v2_event_into_v1(orig_event = nil, map_label = 'json_attributes')
        orig_event ||= @event

        # return orig_event if already mapped
        return orig_event if orig_event['v2_event_mapped_into_v1']

        # Deep copy of orig_event
        event = Marshal.load(Marshal.dump(orig_event))

        # Trigger mapping code if enity exists and client does not
        client_missing = event['client'].nil? || event['client'].empty?
        if event.key?('entity') && client_missing
          ##
          # create the client hash from the entity hash
          ##
          event['client'] = event['entity']

          ##
          # Fill in missing client attributes
          ##

          event['client']['subscribers'] ||= event['entity']['subscriptions']

          ##
          #  Map entity metadata into client attributes
          #  Note this is potentially destructive as it may overwrite existing client attributes.
          ##
          if event['entity'].key?('metadata')
            ##
            #  Map metadata label 'name' to client name attribute
            ##
            event['client']['name'] ||= event['entity']['metadata']['name']

            ##
            #  Map special metadata label defined in map_label as json string and convert to client attributes
            #  Note this is potentially destructive as it may overwrite existing client attributes.
            ##
            if event['entity']['metadata'].key?('labels') && event['entity']['metadata']['labels'].key?(map_label)
              json_hash = JSON.parse(event['entity']['metadata']['labels'][map_label])
              event['client'].update(json_hash)
            end
          end

          ##
          # Fill in renamed check attributes expected in 1.4 event
          #   subscribers, source
          ##
          event['check']['subscribers'] ||= event['check']['subscriptions']
          event['check']['source'] ||= event['check']['proxy_entity_name']

          ##
          # Mimic 1.4 event action based on 2.0 event state
          #  action used in logs and fluentd plugins handlers
          ##
          action_state_mapping = {
            'flapping' => 'flapping',
            'passing' => 'resolve',
            'failing' => 'create'
          }

          state = event['check']['state'] || 'unknown::2.0_event'

          # Attempt to map 2.0 event state to 1.4 event action
          event['action'] ||= action_state_mapping[state.downcase]
          # Fallback action is 2.0 event state
          event['action'] ||= state

          ##
          # Mimic 1.4 event history based on 2.0 event history
          #  Note: This overwrites the same history attribute
          #    2.x history is an array of hashes, each hash includes status
          #    1.x history is an array of statuses
          ##
          if event['check']['history']
            # Let's save the original history
            history_v2 = Marshal.load(Marshal.dump(event['check']['history']))
            event['check']['history_v2'] = history_v2
            legacy_history = []
            event['check']['history'].each do |h|
              legacy_history << h['status'].to_i.to_s || '3'
            end
            event['check']['history'] = legacy_history
          end

          ##
          # Setting flag indicating this function has already been called
          ##
          event['v2_event_mapped_into_v1'] = true
        end
        # return the updated event
        event
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
