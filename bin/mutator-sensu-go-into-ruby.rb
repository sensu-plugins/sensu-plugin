#!/usr/bin/env ruby

require 'sensu-mutator'

class Helper < Sensu::Mutator
  def mutate
    STDERR.puts 'WARNING: mutator-sensu-go-into-ruby.rb is meant for primarily for development.'
    STDERR.puts 'Please update your handlers to be compatible with Sensu Go events.'
    new_event = map_go_event_into_ruby
    @event = new_event
  end
end
