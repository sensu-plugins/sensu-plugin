require 'net/http'
require 'json'

module Sensu

  NET_HTTP_REQ_CLASS = {
    'GET' => Net::HTTP::Get,
    'POST' => Net::HTTP::Post,
    'DELETE' => Net::HTTP::Delete,
    'PUT' => Net::HTTP::Put,
  }

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
      req = NET_HTTP_REQ_CLASS[method.to_s.upcase].new(path)
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
      occurrences = @event['check']['occurrences'] || 1
      interval    = @event['check']['interval']    || 30
      refresh     = @event['check']['refresh']     || 1800
      if @event['occurrences'] < occurrences
        bail 'not enough occurrences'
      end
      if @event['occurrences'] > occurrences && @event['action'] == 'create'
        number = refresh.fdiv(interval).to_i
        unless @event['occurrences'] % number == 0
          bail 'only handling every ' + number.to_s + ' occurrences'
        end
      end
    end

    def stash_exists?(path)
      api_request(:GET, '/stash' + path).code == '200'
    end

    def filter_silenced
      stashes = {
        'client' => '/silence/' + @event['client']['name'],
        'check'  => '/silence/' + @event['client']['name'] + '/' + @event['check']['name']
      }
      stashes.each do |scope, path|
        begin
          timeout(2) do
            if stash_exists?(path)
              bail scope + ' alerts silenced'
            end
          end
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
          @event['check']['dependencies'].each do |check|
            begin
              timeout(2) do
                if event_exists?(@event['client']['name'], check)
                  bail 'check dependency event exists'
                end
              end
            rescue Timeout::Error
              puts 'timed out while attempting to query the sensu api for an event'
            end
          end
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
