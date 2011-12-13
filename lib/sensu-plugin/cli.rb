require 'sensu-plugin'
require 'mixlib/cli'

module Sensu
  module Plugin
    class CLI
      include Mixlib::CLI

      def format_output(status, output)
        output
      end

      Sensu::Plugin::EXIT_CODES.each do |status, code|
        define_method(status.downcase) do |*args|
          puts format_output(status, *args)
          exit(code)
        end
      end

      def run
        unknown "Not implemented! You should override Sensu::Plugin::CLI#run."
      end

      @@autorun = self
      class << self
        def method_added(name)
          if name == :run
            @@autorun = self
          end
        end
      end

      at_exit do
        check = @@autorun.new
        check.parse_options
        check.run
        warning "Check did not exit! You should call an exit code method."
      end

    end
  end
end
