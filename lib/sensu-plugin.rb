# frozen_string_literal: true

module Sensu
  module Plugin
    VERSION = '3.0.1'
    EXIT_CODES = {
      'OK'       => 0,
      'WARNING'  => 1,
      'CRITICAL' => 2,
      'UNKNOWN'  => 3
    }.freeze
  end
end
