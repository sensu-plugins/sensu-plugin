require 'sensu-plugin/cli'

module Sensu
  module Plugin
    class Check
      class CLI < Sensu::Plugin::CLI

        class << self
          def check_name(name=nil)
            if name
              @check_name = name
            else
              @check_name || self.to_s
            end
          end
        end

        def format_output(status, output)
          "#{self.class.check_name}: #{status} - #{output}"
        end

      end
    end
  end
end
