#!/usr/bin/env ruby

require 'sensu-mutator'

class Helper < Sensu::Mutator
  def mutate
    new_event = map_go_event_into_v1
    @event = new_event
  end
end
