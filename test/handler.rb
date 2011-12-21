#!/usr/bin/env ruby

require 'rubygems'
require 'minitest/autorun'
require 'json'

class TestHandler < MiniTest::Unit::TestCase

  def setup
    @script = File.join(File.dirname(__FILE__), 'handlers/handle-nofilter')
  end

  def run_script(event)
    output = IO.popen(@script, 'r+') do |child|
      child.puts JSON.generate(event)
      child.close_write
      child.read
    end
  end

  def test_handled
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
    }
    output = run_script(event)
    assert $?.exitstatus == 0 && output =~ /Event:.*test/
  end

  def test_missing_keys
    event = {}
    output = run_script(event)
    assert $?.exitstatus == 0 && output =~ /Event:/
  end

end
