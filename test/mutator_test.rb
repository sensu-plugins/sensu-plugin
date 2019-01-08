#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'

require 'test_helper'

# Simple Heper to test mutator
class TestMutatorHelpers < MiniTest::Test
  include SensuPluginTestHelper
  def test_base_mutator
    set_script 'external/mutator-trivial'
    event = JSON.parse(fixture('basic_event.json').read)
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_equal(event, JSON.parse(output))
  end

  def test_external_mutator
    set_script 'external/mutator-helpers'
    event = JSON.parse(fixture('basic_event.json').read)
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_equal(true, JSON.parse(output)['mutated'])
  end
end
