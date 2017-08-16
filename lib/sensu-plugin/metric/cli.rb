require 'sensu-plugin/cli'
require 'json'

module Sensu
  module Plugin
    class Metric
      class CLI
        class JSON < Sensu::Plugin::CLI
          def output(obj = nil)
            if obj.is_a?(String) || obj.is_a?(Exception)
              puts obj.to_s
            elsif obj.is_a?(Hash)
              obj['timestamp'] ||= Time.now.to_i
              puts ::JSON.generate(obj)
            end
          end
        end

        class Graphite < Sensu::Plugin::CLI
          # Outputs metrics using the Statsd datagram format
          #
          # @param args [Array<String, Int>] list of arguments
          # @note the argument order should be:
          #   `metric_path`: Mandatory, name for the metric,
          #   `value`: Mandatory, metric value
          #   `timestamp`: Optional, unix timestamp, defaults to current time
          # @return [String] formated metric data
          def output(*args)
            return if args.empty?
            if args[0].is_a?(Exception) || args[1].nil?
              puts args[0].to_s
            else
              args[2] ||= Time.now.to_i
              puts args[0..2].join("\s")
            end
          end
        end

        class Statsd < Sensu::Plugin::CLI
          # Outputs metrics using the Statsd datagram format
          #
          # @param args [Array<String, Int>] list of arguments
          # @note the argument order should be:
          #   `metric_name`: Mandatory, name for the metric,
          #   `value`: Mandatory, metric value
          #   `type`: Optional, metric type- `c` for counter, `g` for gauge, `ms` for timer, `s` for set
          # @return [String] formated metric data
          def output(*args)
            return if args.empty?
            if args[0].is_a?(Exception) || args[1].nil?
              puts args[0].to_s
            else
              type = args[2] || 'kv'
              puts [args[0..1].join(':'), type].join('|')
            end
          end
        end

        class Dogstatsd < Sensu::Plugin::CLI
          # Outputs metrics using the DogStatsd datagram format
          #
          # @param args [Array<String, Int>] list of arguments
          # @note the argument order should be:
          #   `metric_name`: Mandatory, name for the metric,
          #   `value`: Mandatory, metric value
          #   `type`: Optional, metric type- `c` for counter, `g` for gauge, `ms` for timer, `h` for histogram, `s` for set
          #   `tags`: Optional, a comma separated key:value string `tag1:value1,tag2:value2`
          # @return [String] formated metric data
          def output(*args)
            return if args.empty?
            if args[0].is_a?(Exception) || args[1].nil?
              puts args[0].to_s
            else
              type = args[2] || 'kv'
              tags = args[3] ? "##{args[3]}" : nil
              puts [args[0..1].join(':'), type, tags].compact.join('|')
            end
          end
        end

        class Influxdb < Sensu::Plugin::CLI
          # Outputs metrics using the InfluxDB line protocol format
          #
          # @param args [Array<String, Int>] list of arguments
          # @note the argument order should be:
          #   `measurement_name`: Mandatory, name for the InfluxDB measurement,
          #   `fields`: Mandatory, either an integer or a comma separated key=value string `field1=value1,field2=value2`
          #   `tags`: Optional, a comma separated key=value string `tag1=value1,tag2=value2`
          #   `timestamp`: Optional, unix timestamp, defaults to current time
          # @return [String] formated metric data
          def output(*args)
            return if args.empty?
            if args[0].is_a?(Exception) || args[1].nil?
              puts args[0].to_s
            else
              fields = if args[1].is_a?(Integer)
                         "value=#{args[1]}"
                       else
                         args[1]
                       end
              measurement = [args[0], args[2]].compact.join(',')
              ts = args[3] || Time.now.to_i
              puts [measurement, fields, ts].join(' ')
            end
          end
        end
      end
    end
  end
end
