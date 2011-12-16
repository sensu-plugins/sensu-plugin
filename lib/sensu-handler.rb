require 'json'
require 'sensu/config'

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

    # Unfortunately, we need to reimplement config loading. I'm not sure there's
    # a good way to allow overriding these paths.

    CONFIGS = ['/etc/sensu/config.json'] + Dir['/etc/sensu/conf.d/*.json']

    def load_config(filename)
      JSON.parse(File.open(filename, 'r').read) rescue Hash.new
    end

    def settings
      @settings ||= CONFIGS.map {|f| load_config(f) }.reduce {|a, b| a.deep_merge(b) }
    end

    at_exit do
      handler = @@autorun.new
      event = ::JSON.parse(STDIN.read)
      if handler.filter(event)
        handler.handle(event)
      end
    end

  end
end

# Copied from Sensu (0.8.19)

class Hash
  def deep_merge(hash)
    merger = proc do |key, value1, value2|
      value1.is_a?(Hash) && value2.is_a?(Hash) ? value1.merge(value2, &merger) : value2
    end
    self.merge(hash, &merger)
  end
end
