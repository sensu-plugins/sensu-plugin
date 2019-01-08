# frozen_string_literal: true

require 'test_helper'
require 'English'

class TestHandleHelpers < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-helpers'
  end

  def test_event_summary
    event = {
      'client' => {
        'name' => 'test'
      },
      'check' => {
        'name' => 'test',
        'output' => 'test',
        'status' => 0
      },
      'occurrences' => 1,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match("test/test : test\n", output)
    event['check']['source'] = 'switch-x'
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match("switch-x/test : test\n", output)
    event['check']['description'] = 'y is broken'
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match("y is broken\n", output)
    event['check']['notification'] = 'z is broken'
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match("z is broken\n", output)
  end
end
