module Sensu
  module Plugin
    module Utils

      def config_files
        if ENV['SENSU_CONFIG_FILES']
          ENV['SENSU_CONFIG_FILES'].split(':')
        else
          ['/etc/sensu/config.json'] + Dir['/etc/sensu/conf.d/*.json']
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
        rescue => error
          puts 'error reading event: ' + error.message
          exit 0
        end
      end

    end
  end
end
