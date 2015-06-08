require 'net/http'
require 'json'
require 'sensu-plugin/utils'
require 'mixlib/cli'

module Sensu

  class Handler
    include Sensu::Plugin::Utils
    include Mixlib::CLI

    attr_accessor :argv

    def initialize(argv = ARGV)
      super()
      self.argv = parse_options(argv)
    end

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
      filter_dependencies
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

    def self.disable_autorun
      @@autorun = false
    end

    at_exit do
      if @@autorun
        handler = @@autorun.new
        handler.read_event(STDIN)
        handler.filter
        handler.handle
      end
    end

    # Helpers and filters.

    def event_summary(trim_at=100)
      summary = @event['check']['notification'] || @event['check']['description']
      if summary.nil?
        source = @event['check']['source'] || @event['client']['name']
        event_context = [source, @event['check']['name']].join('/')
        output = @event['check']['output'].chomp
        output = output.length > trim_at ? output[0..trim_at] + '...' : output
        summary = [event_context, output].join(' : ')
      end
      summary
    end

    def bail(msg)
      puts msg + ': ' + @event['client']['name'] + '/' + @event['check']['name']
      exit 0
    end

    def api_request(method, path, &blk)
      if not settings.has_key?('api')
        raise "api.json settings not found."
      end
      http = Net::HTTP.new(settings['api']['host'], settings['api']['port'])
      req = net_http_req_class(method).new(path)
      if settings['api']['user'] && settings['api']['password']
        req.basic_auth(settings['api']['user'], settings['api']['password'])
      end
      yield(req) if block_given?
      http.request(req)
    end

    def filter_disabled
      if @event['check']['alert'] == false
        bail 'alert disabled'
      end
    end

    def filter_repeated
      defaults = {
        'occurrences' => 1,
        'interval' => 30,
        'refresh' => 1800
      }

      if settings['sensu_plugin'].is_a?(Hash)
        defaults.merge!(settings['sensu_plugin'])
      end

      occurrences = (@event['check']['occurrences'] || defaults['occurrences']).to_i
      interval = (@event['check']['interval'] || defaults['interval']).to_i
      refresh = (@event['check']['refresh'] || defaults['refresh']).to_i
      if @event['occurrences'] < occurrences
        bail 'not enough occurrences'
      end
      if @event['occurrences'] > occurrences && @event['action'] == 'create'
        number = refresh.fdiv(interval).to_i
        unless number == 0 || @event['occurrences'] % number == 0
          bail 'only handling every ' + number.to_s + ' occurrences'
        end
      end
    end

    def stash_exists?(path)
      api_request(:GET, '/stash' + path).code == '200'
    end

    def filter_silenced
      stashes = [
        ['client', '/silence/' + @event['client']['name']],
        ['check', '/silence/' + @event['client']['name'] + '/' + @event['check']['name']],
        ['check', '/silence/all/' + @event['check']['name']]
      ]
      stashes.each do |(scope, path)|
        begin
          timeout(2) do
            if stash_exists?(path)
              bail scope + ' alerts silenced'
            end
          end
        rescue Errno::ECONNREFUSED
          puts 'connection refused attempting to query the sensu api for a stash'
        rescue Timeout::Error
          puts 'timed out while attempting to query the sensu api for a stash'
        end
      end
    end

    def event_exists?(client, check)
      api_request(:GET, '/event/' + client + '/' + check).code == '200'
    end

    def filter_dependencies
      if @event['check'].has_key?('dependencies')
        if @event['check']['dependencies'].is_a?(Array)
          @event['check']['dependencies'].each do |dependency|
            begin
              timeout(2) do
                check, client = dependency.split('/').reverse
                if event_exists?(client || @event['client']['name'], check)
                  bail 'check dependency event exists'
                end
              end
            rescue Errno::ECONNREFUSED
              puts 'connection refused attempting to query the sensu api for an event'
            rescue Timeout::Error
              puts 'timed out while attempting to query the sensu api for an event'
            end
          end
        end
      end
    end

  end

end
