require 'sensu-plugin'
require 'mixlib/cli'

module Sensu
  module Plugin
    class CLI
      include Mixlib::CLI

      attr_accessor :argv

      def initialize(argv=ARGV)
        super()
        self.argv = self.parse_options(argv)
      end

      # Implementing classes should override this to produce appropriate
      # output for their handler.

      def output(*args)
        puts "Sensu::Plugin::CLI: #{args}"
      end

      # This will define 'ok', 'warning', 'critical', and 'unknown'
      # methods, which the plugin should call to exit.

      Sensu::Plugin::EXIT_CODES.each do |status, code|
        define_method(status.downcase) do |*args|
          @status = status
          output(*args)
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
        begin
          check = @@autorun.new
          check.run
        rescue SystemExit => e
          exit e.status
        rescue Exception => e
          # This can't call check.critical, as the check may have failed to construct
          puts "Sensu::Plugin::CLI: Check failed to run: #{e.message}, #{e.backtrace}"
          exit 2
        end
        check.warning "Check did not exit! You should call an exit code method."
      end

    end
  end
end
