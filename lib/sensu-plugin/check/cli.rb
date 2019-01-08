# frozen_string_literal: false

require 'sensu-plugin/cli'

module Sensu
  module Plugin
    class Check
      class CLI < Sensu::Plugin::CLI
        class << self
          def check_name(name = nil)
            if name
              @check_name = name
            else
              @check_name || to_s
            end
          end
        end

        def message(msg)
          @message = msg
        end

        def output(msg = @message)
          puts "#{self.class.check_name} #{@status}" + (msg ? ": #{msg}" : '')
        end
      end
    end
  end
end
