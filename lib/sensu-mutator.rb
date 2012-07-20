module Sensu
  class Mutator
    include Sensu::Plugin::Utils

    # Implementing classes should override this.

    def mutate; end

    # This works just like Plugin::CLI's autorun.

    @@autorun = self
    class << self
      def method_added(name)
        if name == :mutate
          @@autorun = self
        end
      end
    end

    def read_event(file)
      begin
        @event = ::JSON.parse(file.read)
      rescue => error
        exit 2
      end
    end

    at_exit do
      mutator = @@autorun.new
      mutator.read_event(STDIN)
      mutator.mutate
    end

  end
end
