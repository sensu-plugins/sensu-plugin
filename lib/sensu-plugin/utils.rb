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
      #      be used in a 2.0 workflow. The top level boolean attribute "2to1" 
      #      will be set to true as a hint to indicate this is a mapped event object.
      #
      ##
      def event_2to1(orig_event=nil)
        orig_event||=@event
        # Deep copy of orig_event
        event = Marshal::load(Marshal.dump(orig_event))
        # Trigger mapping code iff enity exists and client does not 
        client_missing = event['client'].nil? || event['client'].empty?
        if event.key?('entity') && client_missing
          ##
          # create the client hash from the entity hash
          ##
          event['client'] = event['entity']

          ##
          # Fill in missing client attributes
          ##
          # 
          event['client']['name']        ||= event['entity']['id']
          event['client']['subscribers'] ||= event['entity']['subscriptions']

          ##
          # Fill in missing check attributes
          #   subscribers, source, total_state_change
          ##
          event['check']['subscribers'] ||= event['check']['subscriptions'] 
          event['check']['source'] ||= event['check']['proxy_entity_id'] unless
            event['check']['proxy_entity_id'].nil? || event['check']['proxy_entity_id'].empty?

         
          ##
          # This maybe an oops in the 2.0 event codebase, adding it for now.
          #   Ref: https://github.com/sensu/sensu-go/issues/1869
          ##
          event['check']['total_state_change'] ||= event['check']['total_state-change'] unless
            event['check']['total_state-change'].nil? || event['check']['total_state-change'].empty?


          ##
          # Mimic 1.4 event action based on 2.0 event state
          #  action used in logs and fluentd plugins     
          ##
          state = event['check']['state'] || 'unknown::2.0_event'
          event['action'] ||= 'flapping' if state.casecmp('flapping') == 0
          event['action'] ||= 'resolve' if state.casecmp('passing') == 0
          event['action'] ||= 'create' if state.casecmp('failing') == 0
          event['action'] ||= state

          ##
          # Mimic 1.4 event history based on 2.0 event history
          #  Note: This overwrites the same history attribute
          #    2.x history is an array of hashes, each hash includes status
          #    1.x history is an array of statuses
          ##
          if event['check']['history']
            legacy_history = []
            event['check']['history'].each do |h|
              legacy_history << h['status'].to_s || '3'
            end
            event['check']['history'] = legacy_history
          end

          ##
          # Setting flag indicating this function has already been called
          ## 
          event['2to1'] = true
        end
        # return the updated event 
        return event
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
