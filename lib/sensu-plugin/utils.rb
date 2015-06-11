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
        @settings ||= config_files.map {|f| load_config(f) }.reduce {|a, b| a.deep_merge(b) }
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
    end
  end
end

# Monkey Patching.

class Array
  def deep_merge(other_array, &merger)
    concat(other_array).uniq
  end
end

class Hash
  def deep_merge(other_hash, &merger)
    merger ||= proc do |key, old_value, new_value|
      old_value.deep_merge(new_value, &merger) rescue new_value
    end
    merge(other_hash, &merger)
  end
end
