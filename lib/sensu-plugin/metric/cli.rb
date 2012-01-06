require 'sensu-plugin/cli'
require 'json'

module Sensu
  module Plugin
    class Metric
      class CLI < Sensu::Plugin::CLI

        def format_output(status, output)
          output['timestamp'] ||= Time.now.to_i
          ::JSON.generate(output)
        end

      end
    end
  end
end
