require 'rubygems'
require 'minitest/autorun'
begin
  # Attempt to load the json.rb file if available
  require 'json'
rescue LoadError
  # Look for a json ruby gem
  require 'rubygems'
  begin
    require 'json_pure'
  rescue LoadError
    begin
      require 'json-ruby'
    rescue LoadError
      require 'json'
    end
  end
end

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
