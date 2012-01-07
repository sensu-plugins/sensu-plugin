require 'sensu-plugin/cli'
require 'json'

module Sensu
  module Plugin
    class Metric
      class CLI

        class JSON < Sensu::Plugin::CLI
          def output(obj=nil)
            unless obj.nil? || obj.is_a?(String) || obj.is_a?(Exception)
              obj['timestamp'] ||= Time.now.to_i
              puts ::JSON.generate(obj)
            end
          end
        end

        class Graphite < Sensu::Plugin::CLI
          def output(path=nil, value=nil, timestamp=Time.now.to_i)
            unless path.nil? || path.is_a?(Exception) || value.nil?
              puts [path, value, timestamp].join("\t")
            end
          end
        end

      end
    end
  end
end
