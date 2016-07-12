require 'test_helper'
require 'json'

class TestFilterExternal < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-filter'
  end


  def test_create_not_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'occurrences' => 2 },
      'occurrences' => 1,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/^not enough occurrences/, output)
  end

  def test_create_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'occurrences' => 2 },
      'occurrences' => 2,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/^Event:/, output)
  end

  def test_resolve_not_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'occurrences' => 2 },
      'occurrences' => 1,
      'action' => 'resolve'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/^not enough occurrences/, output)
  end

  def test_resolve_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'occurrences' => 2 },
      'occurrences' => 2,
      'action' => 'resolve'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/^Event:/, output)
  end

  def test_refresh_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 61,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/^Event:/, output)
  end

  def test_refresh_not_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 60,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/^only handling every/, output)
  end

  def test_refresh_bypass
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'refresh' => 0 },
      'occurrences' => 60,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/^Event:/, output)
  end

  def test_refresh_less_than_interval
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'refresh' => 30 },
      'occurrences' => 60,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/^Event:/, output)
  end

  def test_dependency_event_exists
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'dependencies' => ['foo', 'bar'] },
      'occurrences' => 1
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/dependency event exists/, output)
  end

  def test_state_changed_resolve_after_fail
   event = {
   'client' => { 'name' => 'test' },
   'check' => { 'name' => 'test', 'occurrences' => 3, 'history' => %w[1 1 1 0]},
   'occurrences' => 3,
   'action' => 'resolve'
   }
   output = run_script_with_input(JSON.generate(event))
   assert_equal(0, $?.exitstatus)
   assert_match(/^Event:/, output)
  end

  def test_resolve_after_fail_then_nonzero_state_change
   event = {
   'client' => { 'name' => 'test' },
   'check' => { 'name' => 'test', 'occurrences' => 3, 'history' => %w[1 1 1 2 0]},
   'occurrences' => 1,
   'action' => 'resolve'
   }
   output = run_script_with_input(JSON.generate(event))
   assert_equal(0, $?.exitstatus)
   assert_match(/^Event:/, output)
  end

  def test_resolve_after_fail_then_extra_nonzero_state_change
   event = {
   'client' => { 'name' => 'test' },
   'check' => { 'name' => 'test', 'occurrences' => 3, 'history' => %w[1 1 1 2 2 0]},
   'occurrences' => 1,
   'action' => 'resolve'
   }
   output = run_script_with_input(JSON.generate(event))
   assert_equal(0, $?.exitstatus)
   assert_match(/^Event:/, output)
  end

  def IGNORE_BROKEN_test_resolve_after_fail_then_multiple_nonzero_state_change
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'occurrences' => 3, 'history' => %w[1 1 1 2 3 0]},
      'occurrences' => 1,
      'action' => 'resolve'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/^Event:/, output)
  end
end
