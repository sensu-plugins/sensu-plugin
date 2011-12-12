require 'sensu/plugin'
require 'mixlib/cli'

module Sensu
  module Plugin
    class Check
      class CLI
        include Mixlib::CLI

        Sensu::Plugin::EXIT_CODES.each do |status, code|
          define_method(status.downcase) do |msg|
            puts "#{self.class.check_name}: #{status} - #{msg}"
            code
          end
        end

        class << self
          def check_name(name=nil)
            if name
              @check_name = name
            else
              @check_name || self.to_s
            end
          end
        end

        def run
          unknown "No check implemented! You should override Sensu::Plugin::Check::CLI#run."
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
          exit(check.run)
        end

      end
    end
  end
end
