require 'net/http'
require 'json'
require 'sensu-plugin/utils'

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
      filter_dependencies
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

    def api_request(method, path, &blk)
      http = Net::HTTP.new(settings['api']['host'], settings['api']['port'])
      req = net_http_req_class(method).new(path)
      if settings['api']['user'] && settings['api']['password']
        req.basic_auth(settings['api']['user'], settings['api']['password'])
      end

      req.body = {}.to_json if method == :POST
      yield(req) if block_given?
      http.request(req)
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
      stashes = [
        mkpath("stashes", "silence", @event['client']['name']),
        mkpath("stashes", "silence", @event['client']['name'], @event['check']['name']),
        mkpath("stashes", "silence", "all", @event['check']['name'])
      ]
      stashes.each do |path|
        bail "found %s" % path if exists? path
      end
    end

    def exists?(path)
      timeout(2) do
        api_request(:GET, path).code == '200'
      end
    rescue Timeout::Error
      puts 'timed out while attempting to query the sensu api'
    end

    def mkpath(*args)
      "/%s" % args.compact.join("/")
    end

    def silence_dependant(check = nil)
      if settings['auto_silence_dependencies']
        path = mkpath("stashes", "silence", @event['client']['name'], check)
        unless exists? path
          puts "Adding %s" % path
          api_request :POST, path
        end
      end
    end

    def filter_dependencies
      @event['client']['dependencies'].each do |client, checks|
        checks.each do |check|
          path = mkpath("events", client, check)
          if exists? path
            silence_dependant
            bail "bailing since I depend on %s " % path
          end
        end
      end if @event['client']['dependencies']

      @event['check']['dependencies'].each do |check|
        path = mkpath("events", @event['client']['name'], check)
        if exists? path
          silence_dependant check
          bail "bailing since I depend on %s " % path
        end
      end if @event['check']['dependencies']
    end

  end
end
