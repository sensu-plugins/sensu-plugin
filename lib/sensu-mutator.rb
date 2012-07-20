module Sensu

  class Mutator

    # Implementing classes should override this.

    def mutate; end

    # This works just like Plugin::CLI's autorun.

    @@autorun = self
    class << self
      def method_added(name)
        if name == :mutate
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
        exit 2
      end
    end

    at_exit do
      mutator = @@autorun.new
      mutator.read_event(STDIN)
      mutator.mutate
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
