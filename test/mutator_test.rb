#!/usr/bin/env ruby

require 'test_helper'

# Simple Heper to test mutator
class TestMutatorHelpers < MiniTest::Test
  include SensuPluginTestHelper
  def test_base_mutator
    set_script 'external/mutator-trivial'
    event = Sensu::JSON.load(fixture('basic_event.json').read)
    output = run_script_with_input(Sensu::JSON.dump(event))
    assert_equal(0, $?.exitstatus)
    assert_equal(event, Sensu::JSON.load(output))
  end

  def test_external_mutator
    set_script 'external/mutator-helpers'
    event = Sensu::JSON.load(fixture('basic_event.json').read)
    output = run_script_with_input(Sensu::JSON.dump(event))
    assert_equal(0, $?.exitstatus)
    assert_equal(true, Sensu::JSON.load(output)[:mutated])
  end
end
