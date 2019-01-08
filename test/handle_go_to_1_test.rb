# frozen_string_literal: true

require 'test_helper'
require 'English'

class TestHandleGoto1 < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-go-to-ruby --map-go-event-into-ruby'
  end

  def test_go_to_ruby_enabled
    event = JSON.parse(fixture('basic_go_event.json').read)
    expected = "test_entity : top_value : test_check : test_proxy : test_output : 4 : create : sub1|sub2|sub3 : sub1^sub2^sub3 : potato : 01230\n"
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(expected, output)
  end
end
