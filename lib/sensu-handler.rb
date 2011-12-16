require 'json'

module Sensu
  class Handler

    # Implementing classes should override this.

    def handle(event)
      puts 'ignoring event -- no handler defined'
    end

    # Overriding filtering logic is optional. Returns truthy if the
    # event should be handled and falsy if it should not.

    def filter(event)
      if event['check']['alert'] == false
        puts 'alert disabled -- filtered event ' + short_name(event)
        exit 0
      end
      refresh = (60.fdiv(event['check']['interval']) * 30).to_i
      event['occurrences'] == 1 || event['occurrences'] % refresh == 0
    end

    def short_name(event)
      event['client']['name'] + '/' + event['check']['name']
    end

    # This works just like Plugin::CLI's autorun.

    @@autorun = self
    class << self
      def method_added(name)
        if name == :handle
          @@autorun = self
        end
      end
    end

    SITE_CONFIG_DIR = '/etc/sensu/site-config'

    attr_accessor :config

    @@site_config = nil
    class << self
      def site_config(name)
        config_file = File.join(SITE_CONFIG_DIR, "#{name}.json")
        if File.readable?(config_file)
          begin
            @@site_config = JSON.parse(File.open(config_file, 'r').read)
          rescue JSON::ParserError => e
            puts "configuration file must be valid JSON: #{e}"
            exit 2
          end
        else
          puts "configuration file does not exist or is not readable: #{config_file}"
          exit 2
        end
      end
    end

    at_exit do
      handler = @@autorun.new
      handler.config = @@site_config if @@site_config
      event = ::JSON.parse(STDIN.read)
      if handler.filter(event)
        handler.handle(event)
      end
    end

  end
end
