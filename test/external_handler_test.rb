# frozen_string_literal: true

require 'test_helper'
require 'English'
require 'json'

class TestHandlerExternal < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-nofilter'
  end

  def test_handled
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1
    }
    output = run_script_with_input(JSON.generate(event))
    assert $CHILD_STATUS.success? && output =~ /Event:.*test/
  end

  def test_missing_keys
    event = {}
    output = run_script_with_input(JSON.generate(event))
    assert $CHILD_STATUS.success? && output =~ /Event:/
  end
end
