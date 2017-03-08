require 'net/http'
require 'timeout'
require 'uri'
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
    #
    # Filtering events is deprecated and will be removed in a future release.
    #
    def filter
      if deprecated_filtering_enabled?
        puts 'warning: event filtering in sensu-plugin is deprecated, see http://bit.ly/sensu-plugin'
        filter_disabled
        filter_silenced
        filter_dependencies
        if deprecated_occurrence_filtering_enabled?
          puts 'warning: occurrence filtering in sensu-plugin is deprecated, see http://bit.ly/sensu-plugin'
          filter_repeated
        end
      end
    end

    # Evaluates whether the event should be processed by any of the
    # filter methods in this library. Defaults to true,
    # i.e. deprecated filters are run by default.
    #
    # @return [TrueClass, FalseClass]
    def deprecated_filtering_enabled?
      @event['check']['enable_deprecated_filtering'].to_s == "true"
    end

    # Evaluates whether the event should be processed by the
    # filter_repeated method. Defaults to true, i.e. filter_repeated
    # will filter events by default.
    #
    # @return [TrueClass, FalseClass]
    def deprecated_occurrence_filtering_enabled?
      @event['check']['enable_deprecated_occurrence_filtering'].nil? || \
      @event['check']['enable_deprecated_occurrence_filtering'].to_s == "true"
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
      client_name = @event['client']['name'] || 'error:no-client-name'
      check_name = @event['check']['name'] || 'error:no-check-name'
      puts "#{msg}: #{client_name}/#{check_name}"
      exit 0
    end

    # Return a hash of API settings derived first from ENV['SENSU_API_URL'] if set,
    # then Sensu config `api` scope if configured, and finally falling back to
    # to ipv4 localhost address on default API port.
    #
    # @return [Hash]
    def api_settings
      return @api_settings if @api_settings
      case
      when ENV['SENSU_API_URL']
        uri = URI(ENV['SENSU_API_URL'])
        @api_settings = {
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

    def api_request(method, path, &blk)
      if api_settings.nil?
        raise "api.json settings not found."
      end
      domain = api_settings['host'].start_with?('http') ? api_settings['host'] : 'http://' + api_settings['host']
      uri = URI("#{domain}:#{api_settings['port']}#{path}")
      req = net_http_req_class(method).new(uri.path)
      if api_settings['user'] && api_settings['password']
        req.basic_auth(api_settings['user'], api_settings['password'])
      end
      yield(req) if block_given?
      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.request(req)
      end
      res
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
        unless number == 0 || (@event['occurrences'] - occurrences) % number == 0
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
          Timeout.timeout(5) do
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
      api_request(:GET, '/events/' + client + '/' + check).code == '200'
    end

    def filter_dependencies
      if @event['check'].has_key?('dependencies')
        if @event['check']['dependencies'].is_a?(Array)
          @event['check']['dependencies'].each do |dependency|
            begin
              next if dependency.to_s.empty?
              Timeout.timeout(2) do
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
