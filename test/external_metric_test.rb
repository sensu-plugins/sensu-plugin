require 'test_helper'

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
    assert lines.size == 2 && lines.all? {|line| line.split("\s").size == 3 }
  end

end

class TestStatsdMetricExternal < MiniTest::Unit::TestCase
  include SensuPluginTestHelper

  def setup
    set_script 'external/statsd-output'
  end

  def test_statsd
    lines = run_script.split("\n")
    assert lines.size == 2
    lines.each do |line|
      assert line.split('|').size == 2
      assert line.split('|').first.split(':').size == 2
    end
  end

end

