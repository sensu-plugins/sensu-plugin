#!/usr/bin/env ruby

require 'rubygems'
require 'minitest/autorun'

class TestCheckExternal < MiniTest::Unit::TestCase

  def setup
    @script = File.join(File.dirname(__FILE__), 'external/check-options')
  end

  def run_script(*args)
    IO.popen([@script] + args, 'r+') do |child|
      child.read
    end
  end

  def test_ok
    run_script '-o'
    assert $?.exitstatus == 0
  end

  def test_warning
    run_script '-w'
    assert $?.exitstatus == 1
  end

  def test_critical
    run_script '-c'
    assert $?.exitstatus == 2
  end

  def test_unknown
    run_script '-u'
    assert $?.exitstatus == 3
  end

  def test_fallthrough
    run_script
    assert $?.exitstatus == 1
  end

  def test_argv
    output = run_script '-o', 'foo'
    assert $?.exitstatus == 0 && output.include?('argv = foo')
  end

end
