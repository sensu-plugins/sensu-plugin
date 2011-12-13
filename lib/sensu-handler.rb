require 'json'

module Sensu
  class Handler

    # Implementing classes should override this.

    def handle(event)
      puts 'ignoring event -- no handler defined'
    end

    # Overriding filtering logic is optional. Returns truthy if the
    # event should be handled and falsy if it should not.

    def filter(event)
      if event['check']['alert'] == false
        puts 'alert disabled -- filtered event ' + short_name(event)
        exit 0
      end
      refresh = (60.fdiv(event['check']['interval']) * 30).to_i
      event['occurrences'] == 1 || event['occurrences'] % refresh == 0
    end

    def short_name(event)
      event['client']['name'] + '/' + event['check']['name']
    end

    # This works just like Plugin::CLI's autorun.

    @@autorun = self
    class << self
      def method_added(name)
        if name == :handle
          @@autorun = self
        end
      end
    end

    at_exit do
      handler = @@autorun.new
      event = ::JSON.parse(STDIN.read)
      if handler.filter(event)
        handler.handle(event)
      end
    end

  end
end
