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

      ##
      #  Helper method to convert Sensu 2.0 event into Sensu 1.4 event
      #    This is here to help keep Sensu Plugin community handlers working
      #    until they natively support 2.0
      ##
      def event_2to1
        if @event.has_key?("entity") && @event["client"].empty?
          # First create the client hash from the entity hash
          @event["client"]=@event["entity"]

          # Fill in missing client attributes
          @event["client"]["name"]||=@event["entity"]["id"]
          @event["client"]["subscribers"]||=@event["entity"]["subscriptions"]
          @event["client"]["timestamp"]||=@event["timestamp"]

          # Fill in missing check attributes

          @event["check"]["source"]||=@event["check"]["proxy_entity_id"] unless @event["check"]["proxy_entity_id"].nil? || @event["check"]["proxy_entity_id"].empty?
 
          @event["check"]["subscribers"]||=@event["check"]["subscriptions"]

          # This maybe an oops in the 2.0 event codebase, adding it for now.
          #   Ref: https://github.com/sensu/sensu-go/issues/1869
          @event["check"]["total_state_change"]||=@event["check"]["total_state-change"]

          ##
          # Mimic 1.4 event action based on 2.0 event state 
          #  action used in logs and fluentd plugins 
          ##
          state = @event["check"]["state"] || 'unknown::2.0_event'
          @event["action"]||="flapping" if state.downcase == "flapping"
          @event["action"]||="resolve"  if state.downcase == "passing"
          @event["action"]||="create"   if state.downcase == "failing"
          @event["action"]||=state  

          ##
          # Mimic 1.4 event history based on 2.0 event history
          ## 
          if  @event["check"]["history"]
            legacy_history = []
            @event["check"]["history"].each do |h|
              legacy_history << "#{h["status"]}" || "3"
            end
            @event["check"]["history"]=legacy_history
          end

          # set unmappable entity attribute explicitly via agent or sensuctl
          @event["client"]["address"]||="unknown::2.0-event"   # Used in several plugins

        end
        puts @event
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
