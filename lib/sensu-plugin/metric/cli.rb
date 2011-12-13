require 'sensu-plugin/cli'
require 'json'

module Sensu
  module Plugin
    class Metric
      class CLI < Sensu::Plugin::CLI

        def format_output(status, output)
          JSON.generate(output.merge(:timestamp => Time.now.to_i))
        end

      end
    end
  end
end
