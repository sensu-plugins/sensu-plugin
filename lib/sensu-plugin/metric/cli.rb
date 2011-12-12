require 'sensu-plugin/cli'
require 'json'

module Sensu
  module Plugin
    class Metric
      class CLI < Sensu::Plugin::CLI

        def format_output(status, output)
          JSON.generate(output)
        end

      end
    end
  end
end
