require 'test_helper'
require 'json'

class TestExternalAck < MiniTest::Test
  include SensuPluginTestHelper

  attr_accessor :output
  attr_accessor :event

  def event_json
    JSON.generate(@event)
  end

  def run_script_with_input(*args)
    args << '2<&1'
    @output = super(*args)
  end

  def action(arg)
    event['action'] = arg.to_s
  end

  def setup
    set_script 'external/handle-acked'
    @event = {
      'client'      => { 'name' => 'test' },
      'check'       => { 'name' => 'test' },
      'occurrences' => 1,
    }
  end

  def test_resolve_when_not_silenced
    action :resolve
    run_script_with_input(event_json)
    assert_match(/^handled/, @output)
    refute_match(/^deleting stash/, @output)
  end

  def test_resolve_when_acked
    action :resolve
    run_script_with_input(event_json, '--acked')
    assert_match(/^handled/, @output)
    assert_match(/^deleting stash/, @output)
  end

  def test_resolve_when_silenced
    action :resolve
    run_script_with_input(event_json, '--stashed')
    assert_match(/alerts silenced/, @output)
  end

  def test_create_when_acked
    action :create
    run_script_with_input(event_json, '--acked')
    assert_match(/alerts silenced/, @output)
  end

  def test_create_when_silenced
    action :create
    run_script_with_input(event_json, '--stashed')
    assert_match(/alerts silenced/, @output)
  end

  def test_create_when_not_silenced
    action :create
    run_script_with_input(event_json)
    assert_match(/handled/, @output)
  end

end
