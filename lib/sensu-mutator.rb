#!/usr/bin/env ruby
# frozen_string_literal: false

#
# Sensu-mutator
# ===
#
# DESCRIPTION:
#   Base mutator class.  All you need to do is extend this class and implement a
#   #mutate function.  Uses the autorun feature just like sensu-handler and sensu-plugin/cli
#
# Example Implementation: described https://sensuapp.org/docs/latest/mutators#example-mutator-plugin
#
# class Helper < Sensu::Mutator
#   def mutate
#     @event.merge!(mutated: true)
#   end
# end
#
# PLATFORM:
#   all
#
# DEPENDENCIES:
#   sensu-plugin/utils
#   mixlib/cli
#
# Copyright 2015 Zach Bintliff <https://github.com/zbintliff>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
require 'json'
require 'sensu-plugin/utils'
require 'mixlib/cli'

module Sensu
  class Mutator
    include Sensu::Plugin::Utils
    include Mixlib::CLI
    option :map_go_event_into_ruby,
           description: 'Enable Sensu Go to Sensu Ruby event mapping. Alternatively set envvar SENSU_MAP_GO_EVENT_INTO_RUBY=1.',
           boolean:     true,
           long:        '--map-go-event-into-ruby'

    attr_accessor :argv

    def initialize(argv = ARGV)
      super()
      self.argv = parse_options(argv)
    end

    def mutate
      ## Override this, be sure any changes are made to @event
      nil
    end

    def dump
      puts JSON.dump(@event)
    end

    # This works just like Plugin::CLI's autorun.
    @@autorun = self
    class << self
      def method_added(name)
        @@autorun = self if name == :mutate
      end
    end

    def self.disable_autorun
      @@autorun = false
    end

    at_exit do
      return unless @@autorun
      mutator = @@autorun.new
      mutator.read_event(STDIN)

      TRUTHY_VALUES = %w[1 t true yes y].freeze
      automap = ENV['SENSU_MAP_GO_EVENT_INTO_RUBY'].to_s.downcase

      if mutator.config[:map_go_event_into_ruby] || TRUTHY_VALUES.include?(automap)
        new_event = mutator.map_go_event_into_ruby
        mutator.event = new_event
      end

      mutator.mutate
      mutator.dump
    end
  end
end
