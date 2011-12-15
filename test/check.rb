#!/usr/bin/env ruby

require 'rubygems'
require 'minitest/autorun'

class TestCheck < MiniTest::Unit::TestCase

  def setup
    @script = File.join(File.dirname(__FILE__), 'checks/check-options')
  end

  def test_ok
    system @script, '-o'
    assert $?.exitstatus == 0
  end

  def test_warning
    system @script, '-w'
    assert $?.exitstatus == 1
  end

  def test_critical
    system @script, '-c'
    assert $?.exitstatus == 2
  end

  def test_unknown
    system @script, '-u'
    assert $?.exitstatus == 3
  end

  def test_fallthrough
    system @script
    assert $?.exitstatus == 1
  end

end
