require 'test_helper'
require 'English'

class TestHandle2to1 < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-2to1 --enable-2to1-mapping'
  end

  def test_2to1_enabled
    event = {
      'entity' => {
        'id' => 'test_entity',
        'subscriptions' => ['sub1', 'sub2', 'sub3']
      },
      'check' => {
        'name' => 'test_check',
        'output' => 'test_output',
        'subscriptions' => ['sub1', 'sub2', 'sub3'],
        'proxy_entity_id' => 'test_proxy',
        'total_state_change' => 1,
        'state' => 'failing',
        'status' => 0
      },
      'occurrences' => 1,
      'action' => 'create'
    }
    expected = "test_entity : test_check : test_proxy : test_output : 1 : create : sub1|sub2|sub3 : sub1^sub2^sub3\n"
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(expected, output)
  end
end
