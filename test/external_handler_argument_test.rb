# frozen_string_literal: true

require 'rubygems'
require 'English'
require 'minitest/autorun'
require 'json'

class TestHandlerArgumentExternal < MiniTest::Test
  include SensuPluginTestHelper

  def test_default
    set_script 'external/handle-argument'
    output = run_script_with_input(JSON.generate({}))
    assert $CHILD_STATUS.success? && output =~ /Value:\sfoo/
  end

  def test_short
    set_script 'external/handle-argument -t bar'
    output = run_script_with_input(JSON.generate({}))
    assert $CHILD_STATUS.success? && output =~ /Value:\sbar/
  end

  def test_long
    set_script 'external/handle-argument --test bar'
    output = run_script_with_input(JSON.generate({}))
    assert $CHILD_STATUS.success? && output =~ /Value:\sbar/
  end
end
