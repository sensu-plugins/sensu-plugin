require 'mixlib/cli'

EXIT_CODES = {
  'OK' => 0,
  'WARNING' => 1,
  'CRITICAL' => 2,
  'UNKNOWN' => 3,
}

class Sensu
  class Plugin
    class Check
      class CLI
        include Mixlib::CLI

        EXIT_CODES.each do |status, code|
          define_method(status.downcase) do |msg|
            puts "#{status}: #{msg}"
            code
          end
        end

        def run
          unknown "No check implemented! You should override Sensu::Check::CLI#run."
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
