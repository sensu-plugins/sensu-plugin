require 'sensu-plugin/cli'
require 'json'

module Sensu
  module Plugin
    class Discovery
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

      end
    end
  end
end
