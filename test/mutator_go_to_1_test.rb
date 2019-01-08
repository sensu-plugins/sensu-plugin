#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'

require 'test_helper'

# Simple Heper to test mutator
class TestMutatorHelpers < MiniTest::Test
  include SensuPluginTestHelper
  def test_base_go_to_1_mutator
    set_script 'external/mutator-trivial --map-go-event-into-ruby'
    event = JSON.parse(fixture('basic_go_event.json').read)
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_equal(event['entity']['metadata']['name'], JSON.parse(output)['client']['name'])
    assert_equal('top_value', JSON.parse(output)['client']['top'])
    assert_equal('nested01_value', JSON.parse(output)['client']['test_json']['nested01'])
    assert_equal('nested02_value', JSON.parse(output)['client']['test_json']['nested02'])
  end

  def test_external_go_to_1_mutator
    set_script 'external/mutator-helpers --map-go-event-into-ruby'
    event = JSON.parse(fixture('basic_go_event.json').read)
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_equal(true, JSON.parse(output)['mutated'])
  end
end
