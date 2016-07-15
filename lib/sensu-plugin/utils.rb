require 'json'

module Sensu
  module Plugin
    module Utils

      def config_files
        if ENV['SENSU_LOADED_TEMPFILE']
          IO.read(ENV['SENSU_LOADED_TEMPFILE']).split(':')
        elsif ENV['SENSU_CONFIG_FILES']
          ENV['SENSU_CONFIG_FILES'].split(':')
        else
          ['/etc/sensu/config.json'] + Dir['/etc/sensu/conf.d/**/*.json']
        end
      end

      def load_config(filename)
        JSON.parse(File.open(filename, 'r').read) rescue Hash.new
      end

      def settings
        @settings ||= config_files.map {|f| load_config(f) }.reduce {|a, b| deep_merge(a, b) }
      end

      def read_event(file)
        begin
          @event = ::JSON.parse(file.read)
          @event['occurrences'] ||= 1
          @event['check']       ||= Hash.new
          @event['client']      ||= Hash.new
        rescue => e
          puts 'error reading event: ' + e.message
          exit 0
        end
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
          merged[key] = case
          when hash_one[key].is_a?(Hash) && value.is_a?(Hash)
            deep_merge(hash_one[key], value)
          when hash_one[key].is_a?(Array) && value.is_a?(Array)
            hash_one[key].concat(value).uniq
          else
            value
          end
        end
        merged
      end
    end
  end
end
