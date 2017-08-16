require 'test_helper'
require 'English'

class TestMetricExternal < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/trivial-metric'
  end

  def test_ok
    output = JSON.parse(run_script)
    assert $CHILD_STATUS.success? && output.key?('timestamp')
  end
end

class TestGraphiteMetricExternal < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/multi-output'
  end

  def test_multi
    lines = run_script.split("\n")
    assert lines.size == 2 && lines.all? { |line| line.split("\s").size == 3 }
  end
end

class TestStatsdMetricExternal < MiniTest::Test
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

class TestDogstatsdMetricExternal < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/dogstatsd-output'
  end

  def test_dogstatsd
    lines = run_script.split("\n")
    assert lines.size == 2
    assert lines.last.split('|').last.split(',').size == 2
    lines.each do |line|
      assert line.split('|').size >= 2
      assert line.split('|').first.split(':').size == 2
    end
  end
end

class TestInfluxdbMetricExternal < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/influxdb-output'
  end

  def test_dogstatsd
    lines = run_script.split("\n")
    assert lines.size == 3
    lines.each do |line|
      assert line.split(' ').size == 3
      assert line.split(' ').first.split(',').size == 3
    end
  end
end
