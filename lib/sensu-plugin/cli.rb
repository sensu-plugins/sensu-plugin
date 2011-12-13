require 'sensu-plugin'
require 'mixlib/cli'

module Sensu
  module Plugin
    class CLI
      include Mixlib::CLI

      # Implementing classes should override this to produce appropriate
      # output for their handler.

      def format_output(status, output)
        output
      end

      # This will define 'ok', 'warning', 'critical', and 'unknown'
      # methods, which the plugin should call to exit.

      Sensu::Plugin::EXIT_CODES.each do |status, code|
        define_method(status.downcase) do |*args|
          puts format_output(status, *args)
          exit(code)
        end
      end

      # Implementing classes must override this.

      def run
        unknown "Not implemented! You should override Sensu::Plugin::CLI#run."
      end

      # Behind-the-scenes stuff below. If you do something crazy like
      # define two plugins in one script, the last one will 'win' in
      # terms of what gets auto-run.

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
