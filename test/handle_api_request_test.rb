require 'test_helper'
#require 'webmock/minitest'

class TestApiRequestExternal < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-api-request'
  end

  def test_stash_exists
    # mocks for /stash/silence/all/test are established in
    # 'external/handle-api-request' fixture
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'silenced_test',
        'refresh' => 30
      },
      'occurrences' => 60,
      'action' => 'create',
    }

    output = run_script_with_input(JSON.generate(event))
    assert_match(/client alerts silenced: test\/silenced_test/, output)
    assert_equal(0, $?.exitstatus)
  end
end
