require 'net/http'
require 'json'

module Sensu
  class Handler

    # Implementing classes should override this.

    def handle
      puts 'ignoring event -- no handler defined'
    end

    # Filters exit the proccess if the event should not be handled.
    # Implementation of the default filters is below.

    def filter
      filter_disabled
      filter_repeated
      filter_silenced
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

    def read_event(file)
      begin
        @event = ::JSON.parse(file.read)
        @event['occurrences'] ||= 1
        @event['check'] ||= Hash.new
        @event['client'] ||= Hash.new
      rescue
        puts 'Error reading event'
        exit 0
      end
    end

    at_exit do
      handler = @@autorun.new
      handler.read_event(STDIN)
      handler.filter
      handler.handle
    end

    # Helpers and filters

    def bail(msg)
      puts msg + ': ' + @event['client']['name'] + '/' + @event['check']['name']
      exit 0
    end

    def api_request(*path)
      http = Net::HTTP.new(settings['api']['host'], settings['api']['port'])
      http.request(Net::HTTP::Get.new(path.join('/')))
    end

    def filter_disabled
      if @event['check']['alert'] == false
        bail 'alert disabled'
      end
    end

    def filter_repeated
      occurrences = @event['check']['occurrences'] || 1
      interval = @event['check']['interval'] || 30
      refresh = @event['check']['refresh'] || 1800
      if @event['occurrences'] < occurrences
        bail 'not enough occurrences'
      end
      if @event['occurrences'] > occurrences
        n = refresh.fdiv(interval).to_i
        bail 'only repeating alert every' + n + 'occurrences' unless @event['occurrences'] % n == 0
      end
    end

    def filter_silenced
      begin
        timeout(3) do
          if api_request('/stash/silence', @event['client']['name']).code == '200'
            bail 'client alerts silenced'
          end
          if api_request('/stash/silence', @event['client']['name'], @event['check']['name']).code == '200'
            bail 'check alerts silenced'
          end
        end
      rescue Timeout::Error
        puts 'Timed out while attempting to query the Sensu API for stashes'
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
