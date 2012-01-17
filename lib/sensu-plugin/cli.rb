require 'sensu-plugin'
require 'mixlib/cli'

module Sensu
  module Plugin
    class CLI
      include Mixlib::CLI

      attr_accessor :argv

      # Implementing classes should override this to produce appropriate
      # output for their handler.

      def output(*args)
        puts "Sensu::Plugin::CLI: #{args}"
      end

      # Implementations of output can call this method to get a "Nagios
      # style" line of text. Sensu plugins can output anything, but this
      # is a familiar format and allows even using a sensu-plugin check
      # from Nagios in a pinch.

      def nagios_style_output(msg=nil)
        name = ENV['SENSU_PLUGIN_NAME'] || self.class.name
        if msg.nil?
          puts "#{name} #{@status}"
        else
          puts "#{name} #{@status}: " + msg.to_s.gsub("\n", ' ')
        end
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
          check.argv = check.parse_options
          check.run
        rescue SystemExit => e
          exit e.status
        rescue Exception => e
          check.critical "Check failed to run: #{e.message}, #{e.backtrace}"
        end
        check.warning "Check did not exit! You should call an exit code method."
      end

    end
  end
end
