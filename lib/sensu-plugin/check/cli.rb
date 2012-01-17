require 'sensu-plugin/cli'

module Sensu
  module Plugin
    class Check
      class CLI < Sensu::Plugin::CLI

        def message(msg)
          @message = msg
        end

        def output(msg=@message)
          nagios_style_output(msg)
        end

      end
    end
  end
end
