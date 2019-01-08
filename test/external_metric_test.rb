# frozen_string_literal: true

require 'test_helper'
require 'English'
require 'json'

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
    assert lines.size == 2
    lines.each do |line|
      assert line.split("\s").size == 3
    end
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
      assert line.split("\s").size == 3
      assert line.split("\s").first.split(',').size == 3
    end
  end
end

class TestGenericMetricsExternal < MiniTest::Test
  include SensuPluginTestHelper

  def test_json
    set_script 'external/generic-metrics --metric_format json'
    lines = run_script.split("\n")
    assert lines.size == 8
    lines.each { |line| assert line.include? 'metric_name' }
  end

  def test_graphite
    set_script 'external/generic-metrics --metric_format graphite'
    lines = run_script.split("\n")
    assert lines.size == 8
    assert lines[1].include? 'metric.name 1'
    assert lines[2].include? 'graphite.metric.path 2'
  end

  def test_statsd
    set_script 'external/generic-metrics --metric_format statsd'
    lines = run_script.split("\n")
    assert lines.size == 8
    assert lines[2].include? 'metric.name:2|kv'
    assert lines[3].include? 'statsd.metric.name:3|s'
    assert lines[4].include? 'metric.name:4|kv'
    assert lines[5].include? 'statsd.metric.name:5|kv'
  end

  def test_dogstatsd
    set_script 'external/generic-metrics --metric_format dogstatsd'
    lines = run_script.split("\n")
    assert lines.size == 8
    assert lines[1].include? 'metric.name:1|kv|#env:prod,location:us-midwest'
    assert lines[2].include? 'metric.name:2|kv|#'
    assert lines[3].include? 'statsd.metric.name:3|s|#'
    assert lines[4].include? 'statsd.metric.name:4|m|#'
    assert lines[5].include? 'dogstatsd.metric.name:5|kv|#'
  end

  def test_influxdb
    set_script 'external/generic-metrics --metric_format influxdb'
    lines = run_script.split("\n")
    assert lines.size == 8
    assert lines[0].include? 'GenericTestMetric, metric.name=0 '
    assert lines[1].include? 'GenericTestMetric,env=prod,location=us-midwest metric.name=1 '
    assert lines[2].include? 'GenericTestMetric, metric.name=2 '
    assert lines[6].include? 'influxdb.measurement, metric.name=6 '
    assert lines[7].include? 'GenericTestMetric, influxdb.field=7 '
  end
end
