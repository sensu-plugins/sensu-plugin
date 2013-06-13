require 'sensu-plugin/check/cli'
require 'json'

module Sensu
  module Plugin
    class Hybird
      class CLI

        class JSON < Sensu::Plugin::Check::CLI
          def json(obj=nil)
            if obj.is_a?(String) || obj.is_a?(Exception)
              @metrics = obj.to_s
            elsif obj.is_a?(Hash)
              obj['timestamp'] ||= Time.now.to_i
              @metrics = ::JSON.generate(obj)
            end
          end

          def output(msg=@message)
            result = { :desciption => "#{self.class.check_name} #{@status}" + (msg ? ": #{msg}" : ""), :metrics => @metrics }
            puts ::JSON.generate(result)
          end
        end

        class Graphite < Sensu::Plugin::Check::CLI
          def metric(*args)
            @metrics ||= String.new
            if args[0].is_a?(Exception) || args[1].nil?
              @metrics << args[0].to_s + "\n"
            else
              args[2] ||= Time.now.to_i
              @metrics << args[0..2].join("\t") + "\n"
            end
          end

          def output(msg=@message)
            result = { :desciption => "#{self.class.check_name} #{@status}" + (msg ? ": #{msg}" : ""), :metrics => @metrics }
            puts ::JSON.generate(result)
          end
        end

      end
    end
  end
end