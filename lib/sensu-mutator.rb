#!/usr/bin/env ruby
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
#     @event.merge!(:mutated => true)
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
require 'sensu/json'
require 'sensu-plugin/utils'
require 'mixlib/cli'

module Sensu
  class Mutator
    include Sensu::Plugin::Utils
    include Mixlib::CLI

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
      puts Sensu::JSON.dump(@event)
    end

    # This works just like Plugin::CLI's autorun.
    @@autorun = self
    class << self
      def method_added(name)
        if name == :mutate
          @@autorun = self
        end
      end
    end

    def self.disable_autorun
      @@autorun = false
    end

    at_exit do
      if @@autorun
        mutator = @@autorun.new
        mutator.read_event(STDIN)
        mutator.mutate
        mutator.dump
      end
    end
  end
end
