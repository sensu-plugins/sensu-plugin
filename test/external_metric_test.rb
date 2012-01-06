#!/usr/bin/env ruby

require 'rubygems'
require 'minitest/autorun'

class TestMetricExternal < MiniTest::Unit::TestCase

  def setup
    @script = File.join(File.dirname(__FILE__), 'external/trivial-metric')
  end

  def run_script(*args)
    IO.popen([@script] + args, 'r+') do |child|
      child.read
    end
  end

  def test_ok
    output = JSON.parse(run_script)
    assert $?.exitstatus == 0 && output.key?('timestamp')
  end

end
