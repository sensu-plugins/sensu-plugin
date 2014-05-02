require 'rubygems'
require 'minitest/autorun'
require 'json'

class TestHandlerArgumentExternal < MiniTest::Unit::TestCase
  include SensuPluginTestHelper

  def test_default
    set_script 'external/handle-argument'
    output = run_script_with_input(JSON.generate({}))
    assert $?.exitstatus == 0 && output =~ /Value:\sfoo/
  end

  def test_short
    set_script 'external/handle-argument -t bar'
    output = run_script_with_input(JSON.generate({}))
    assert $?.exitstatus == 0 && output =~ /Value:\sbar/
  end

  def test_long
    set_script 'external/handle-argument --test bar'
    output = run_script_with_input(JSON.generate({}))
    assert $?.exitstatus == 0 && output =~ /Value:\sbar/
  end
end
