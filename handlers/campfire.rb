# Copyright (c) 2011, Curt Micol <curt@heroku.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN¬
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


require 'rubygems' if RUBY_VERSION < '1.9.0'
require "tinder"

CAMPFIRE_ACCOUNT = "account"
CAMPFIRE_TOKEN = "ccccccccccccccc"
CAMPFIRE_ROOM = "room"

module Sensu
  class Handler
    def self.run
      handler = self.new
      handler.filter
      handler.alert
    end

    def initialize
      read_event
    end

    def read_event
      @event = JSON.parse(STDIN.read)
    end

    def filter
      if @event['check']['alert'] == false
        puts 'alert disabled -- filtered event ' + [@event['client']['name'], @event['check']['name']].join(' : ')
        exit 0
      end
    end

    def alert
      refresh = (60.fdiv(@event['check']['interval']) * 30).to_i
      if @event['occurances'] == 1 || @event['occurances'] % refresh == 0
        campfire
      end
    end

    def campfire
      incident_key = @event['client']['name'] + '/' + @event['check']['name']
      description = [@event['client']['name'], @event['check']['name'], @event['check']['output']].join(' : ')
      begin
        timeout(5) do
          Campfire.say(description)
        end
      rescue Timeout::Error
        puts "campfire -- timed out while trying to send #{incident_key} to IRC"
      end
    end

    module Campfire
      extend self

      def init
        campfire = Tinder::Campfire.new(CAMPFIRE_ACCOUNT, :ssl => true, :token => CAMPFIRE_TOKEN)
        campfire.find_room_by_name(CAMPFIRE_ROOM)
      end

      def say(message)
        room = init
        room.speak(message)
      end
    end
  end
end
