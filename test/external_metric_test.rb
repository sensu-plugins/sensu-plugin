require 'rubygems'
require 'minitest/autorun'

class TestMetricExternal < MiniTest::Unit::TestCase
  include SensuPluginTestHelper

  def setup
    set_script 'external/trivial-metric'
  end

  def test_ok
    output = JSON.parse(run_script)
    assert $?.exitstatus == 0 && output.key?('timestamp')
  end

end
