require 'test_helper'
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

class TestHandlerExternal < MiniTest::Unit::TestCase
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-nofilter'
  end

  def test_handled
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
    }
    output = run_script_with_input(JSON.generate(event))
    assert $?.exitstatus == 0 && output =~ /Event:.*test/
  end

  def test_missing_keys
    event = {}
    output = run_script_with_input(JSON.generate(event))
    assert $?.exitstatus == 0 && output =~ /Event:/
  end

end
