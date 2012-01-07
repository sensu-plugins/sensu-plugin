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

class TestGraphiteMetricExternal < MiniTest::Unit::TestCase
  include SensuPluginTestHelper

  def setup
    set_script 'external/multi-output'
  end

  def test_multi
    lines = run_script.split("\n")
    assert lines.size == 2 && lines.all? {|line| line.split("\t").size == 3 }
  end

end
