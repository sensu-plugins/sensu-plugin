# frozen_string_literal: true

module Sensu
  module Plugin
    VERSION = '4.0.0'
    EXIT_CODES = {
      'OK'       => 0,
      'WARNING'  => 1,
      'CRITICAL' => 2,
      'UNKNOWN'  => 3
    }.freeze
  end
end
