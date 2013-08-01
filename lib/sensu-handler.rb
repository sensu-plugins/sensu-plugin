require 'net/http'
require 'json'
require 'sensu-plugin/utils'
require 'httparty'

module Sensu

  class Handler
    include Sensu::Plugin::Utils

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

    def api_url
      "http://%s:%s" % [settings['api']['host'], settings['api']['port']]
    end

    def http_get(path)
      HTTParty.get "%s/%s" % [api_url, path]
    end

    def http_post(path, data={})
      HTTParty.post("%s/%s" % [api_url, path], {
        body: data.to_json,
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      })
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

    at_exit do
      handler = @@autorun.new
      handler.read_event(STDIN)
      handler.filter
      handler.handle
    end

    # Helpers and filters.

    def bail(msg)
      puts msg + ': ' + @event['client']['name'] + '/' + @event['check']['name']
      exit 0
    end

    def filter_disabled
      if @event['check']['alert'] == false
        bail 'alert disabled'
      end
    end

    def filter_repeated
      occurrences = @event['check']['occurrences'] || 1
      interval    = @event['check']['interval']    || 30
      refresh     = @event['check']['refresh']     || 1800
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

    def filter_silenced
      stashes = {
        'client'       => '/silence/' + @event['client']['name'],
        'client_check' => '/silence/' + @event['client']['name'] + '/' + @event['check']['name'],
        'check'        => '/silence/all/' + @event['check']['name']
      }
      stashes.each do |scope, path|
        timeout(2) do
          if stash_exists? path
            bail scope + ' alerts silenced'
          end
        end
      end
    end

    def stash_exists?(path)
      stash_path = "/stashes/%s" % path
      timeout(2) do
        http_get(stash_path).code == 200
      end
    rescue Timeout::Error
      puts 'timed out while attempting to query the sensu api for a stash'
    end

    def event_exists?(client, check)
      timeout(2) do
        http_get("/event/%s/%s" % [client, check]).code == 200
      end
    rescue Timeout::Error
      puts 'timed out while attempting to query the sensu api for an event'
    end

    def filter_dependencies
      @event['client']['dependencies'].each do |client, checks|
        checks.each do |check|
          if event_exists?(client, check)
            if settings['auto_silence_dependencies']
              unless stash_exists? @event['client']['name']
                http_post "/stashes/silence/%s" % @event['client']['name']
              end
            end
            bail "dependency event exists: %s/%s" % [client, check]
          end
        end
      end if @event['client']['dependencies']

      @event['check']['dependencies'].each do |check|
        if event_exists?(@event['client']['name'], check)
          if settings['auto_silence_dependencies']
            unless stash_exists? "%s/%s" % [@event['client']['name'], check]
              http_post "/stashes/silence/%s/%s" % [@event['client']['name'], check]
            end
          end
          bail "dependency event exists: %s" % check
        end
      end if @event['check']['dependencies']
    end

  end
end
