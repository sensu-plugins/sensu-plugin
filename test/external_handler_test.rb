require 'test_helper'
require 'json'

class TestHandlerExternal < MiniTest::Unit::TestCase
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-nofilter'
  end

  def test_handled
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
    }
    output = run_script_with_input(JSON.generate(event))
    assert $?.exitstatus == 0 && output =~ /Event:.*test/
  end

  def test_missing_keys
    event = {}
    output = run_script_with_input(JSON.generate(event))
    assert $?.exitstatus == 0 && output =~ /Event:/
  end

end
