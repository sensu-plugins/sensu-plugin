# frozen_string_literal: false

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
    option :map_go_event_into_ruby,
           description: 'Enable Sensu Go to Sensu Ruby event mapping. Alternatively set envvar SENSU_MAP_GO_EVENT_INTO_RUBY=1.',
           boolean:     true,
           long:        '--map-go-event-into-ruby'

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
      return unless deprecated_filtering_enabled?
      puts 'warning: event filtering in sensu-plugin is deprecated, see http://bit.ly/sensu-plugin'
      filter_disabled
      filter_silenced
      filter_dependencies
      return unless deprecated_occurrence_filtering_enabled?
      puts 'warning: occurrence filtering in sensu-plugin is deprecated, see http://bit.ly/sensu-plugin'
      filter_repeated
    end

    # Evaluates whether the event should be processed by any of the
    # filter methods in this library. Defaults to true,
    # i.e. deprecated filters are run by default.
    #
    # @return [TrueClass, FalseClass]
    def deprecated_filtering_enabled?
      @event['check'].fetch('enable_deprecated_filtering', false).to_s == 'true'
    end

    # Evaluates whether the event should be processed by the
    # filter_repeated method. Defaults to true, i.e. filter_repeated
    # will filter events by default.
    #
    # @return [TrueClass, FalseClass]
    def deprecated_occurrence_filtering_enabled?
      @event['check'].fetch('enable_deprecated_occurrence_filtering', false).to_s == 'true'
    end

    # This works just like Plugin::CLI's autorun.

    @@autorun = self
    class << self
      def method_added(name)
        @@autorun = self if name == :handle
      end
    end

    def self.disable_autorun
      @@autorun = false
    end

    at_exit do
      if @@autorun
        handler = @@autorun.new
        handler.read_event(STDIN)

        TRUTHY_VALUES = %w[1 t true yes y].freeze
        automap = ENV['SENSU_MAP_GO_EVENT_INTO_RUBY'].to_s.downcase

        if handler.config[:map_go_event_into_ruby] || TRUTHY_VALUES.include?(automap)
          new_event = handler.map_go_event_into_ruby
          handler.event = new_event
        end
        handler.filter
        handler.handle
      end
    end

    # Helpers and filters.

    def event_summary(trim_at = 100)
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

    def filter_disabled
      bail 'alert disabled' if @event['check']['alert'] == false
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
      return unless @event['occurrences'] > occurrences && @event['action'] == 'create'
      number = refresh.fdiv(interval).to_i
      return if number.zero? || ((@event['occurrences'] - occurrences) % number).zero?
      bail 'only handling every ' + number.to_s + ' occurrences'
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
      return unless @event['check'].key?('dependencies')
      return unless @event['check']['dependencies'].is_a?(Array)
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
