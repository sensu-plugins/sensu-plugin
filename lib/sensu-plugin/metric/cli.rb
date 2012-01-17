require 'sensu-plugin/cli'
require 'json'

module Sensu
  module Plugin
    class Metric
      class CLI

        class JSON < Sensu::Plugin::CLI
          def output(obj=nil)
            if obj.respond_to? :[]
              obj['timestamp'] ||= Time.now.to_i
              puts ::JSON.generate(obj)
            else
              # `obj` does not correspond to a JSON object; it's probably
              # a string or exception
              nagios_style_output(obj)
            end
          end
        end

        class Graphite < Sensu::Plugin::CLI
          def output(path=nil, value=nil, timestamp=Time.now.to_i)
            if path.is_a?(String) && value.is_a?(Numeric)
              puts [path, value, timestamp].join("\t")
            elsif path.nil?
              # Do nothing; this is a special case for plugins that
              # output multiple metrics per run
            else
              # In this case, `path` is probably a misnomer, and we've
              # been given a string or exception
              nagios_style_output(path)
            end
          end
        end

      end
    end
  end
end
