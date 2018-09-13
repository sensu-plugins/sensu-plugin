require 'test_helper'
require 'English'

class TestHandle2to1 < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-2to1 --map-v2-event-into-v1'
  end

  def test_2to1_enabled
    event = JSON.parse(fixture('basic_v2_event.json').read)
    expected = "test_entity : test_check : test_proxy : test_output : 4 : create : sub1|sub2|sub3 : sub1^sub2^sub3 : 01230\n"
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(expected, output)
  end
end
