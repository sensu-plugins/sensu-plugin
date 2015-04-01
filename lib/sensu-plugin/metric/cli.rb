require 'sensu-plugin/cli'
begin
  # Attempt to load the json.rb file if available
  require 'json'
rescue LoadError
  # Look for a json ruby gem
  require 'rubygems'
  begin
    require 'json_pure'
  rescue LoadError
    begin
      require 'json-ruby'
    rescue LoadError
      require 'json'
    end
  end
end


module Sensu
  module Plugin
    class Metric
      class CLI

        class JSON < Sensu::Plugin::CLI
          def output(obj=nil)
            if obj.is_a?(String) || obj.is_a?(Exception)
              puts obj.to_s
            elsif obj.is_a?(Hash)
              obj['timestamp'] ||= Time.now.to_i
              puts ::JSON.generate(obj)
            end
          end
        end

        class Graphite < Sensu::Plugin::CLI
          def output(*args)
            if args[0].is_a?(Exception) || args[1].nil?
              puts args[0].to_s
            else
              args[2] ||= Time.now.to_i
              puts args[0..2].join("\s")
            end
          end
        end

        class Statsd < Sensu::Plugin::CLI
          def output(*args)
            if args[0].is_a?(Exception) || args[1].nil?
              puts args[0].to_s
            else
              type = args[2] || 'kv'
              puts [args[0..1].join(':'), type].join('|')
            end
          end
        end

      end
    end
  end
end
