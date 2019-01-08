# frozen_string_literal: true

require 'test_helper'
require 'English'
require 'tempfile'

class TestFilterExternal < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-filter'
  end

  def test_create_not_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'test',
        'occurrences' => 2,
        'enable_deprecated_filtering' => true,
        'enable_deprecated_occurrence_filtering' => true
      },
      'occurrences' => 1,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/^not enough occurrences/, output)
  end

  def test_create_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'test',
        'occurrences' => 2,
        'enable_deprecated_filtering' => true,
        'enable_deprecated_occurrence_filtering' => true
      },
      'occurrences' => 2,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/^Event:/, output)
  end

  def test_resolve_not_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'test',
        'occurrences' => 2,
        'enable_deprecated_filtering' => true,
        'enable_deprecated_occurrence_filtering' => true
      },
      'occurrences' => 1,
      'action' => 'resolve'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/^not enough occurrences/, output)
  end

  def test_resolve_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'test',
        'occurrences' => 2,
        'enable_deprecated_filtering' => true
      },
      'occurrences' => 2,
      'action' => 'resolve'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/^Event:/, output)
  end

  def test_refresh_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'test',
        'enable_deprecated_filtering' => true,
        'enable_deprecated_occurrence_filtering' => true
      },
      'occurrences' => 61,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/^Event:/, output)
  end

  def test_refresh_not_enough_occurrences
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'test',
        'enable_deprecated_filtering' => true,
        'enable_deprecated_occurrence_filtering' => true
      },
      'occurrences' => 60,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
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
    assert_equal(0, $CHILD_STATUS.exitstatus)
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
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/^Event:/, output)
  end

  def test_dependency_event_exists
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'test',
        'dependencies' => ['foo', 'bar'],
        'enable_deprecated_filtering' => true
      },
      'occurrences' => 1
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/dependency event exists/, output)
  end

  def filter_deprecation_string
    'warning: event filtering in sensu-plugin is deprecated, see http://bit.ly/sensu-plugin'
  end

  def test_filter_deprecation_warning_is_not_present_by_default
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'refresh' => 30 },
      'occurrences' => 60,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    refute_match(/#{filter_deprecation_string}/, output)
  end

  def test_filter_deprecation_warning_exists_when_explicitly_enabled
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'refresh' => 30, 'enable_deprecated_filtering' => true },
      'occurrences' => 60,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/#{filter_deprecation_string}/, output)
  end

  def test_filter_deprecation_warning_does_not_exist_when_explicitly_disabled
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'unfiltered test',
        'refresh' => 30,
        'enable_deprecated_filtering' => false
      },
      'occurrences' => 60,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    refute_match(/#{filter_deprecation_string}/, output)
  end

  def test_filter_deprecation_warning_does_not_exist_when_globaly_disabled
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'globaly unfiltered test',
        'refresh' => 30
      },
      'occurrences' => 60,
      'action' => 'create'
    }

    settings_file = Tempfile.new('global_filter_disable')
    settings_file.write('{"sensu_plugin": { "disable_deprecated_filtering": true }}')
    settings_file.close
    ENV['SENSU_CONFIG_FILES'] = settings_file.path
    output = run_script_in_env_with_input(JSON.generate(event), ENV)
    ENV['SENSU_CONFIG_FILES'] = nil
    assert_equal(0, $CHILD_STATUS.exitstatus)
    refute_match(/#{filter_deprecation_string}/, output)
  end

  def occurrence_filter_deprecation_string
    'warning: occurrence filtering in sensu-plugin is deprecated, see http://bit.ly/sensu-plugin'
  end

  def test_occurrence_filter_deprecation_warning_not_present_by_default
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test', 'refresh' => 30 },
      'occurrences' => 60,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    refute_match(/#{occurrence_filter_deprecation_string}/, output)
  end

  def test_occurrence_filter_deprecation_warning_present_when_explicitly_enabled
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'test',
        'refresh' => 30,
        'enable_deprecated_filtering' => true,
        'enable_deprecated_occurrence_filtering' => true
      },
      'occurrences' => 60,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/#{occurrence_filter_deprecation_string}/, output)
  end

  def test_occurrence_filter_deprecation_warning_not_present_when_explicitly_disabled
    event = {
      'client' => { 'name' => 'test' },
      'check' => {
        'name' => 'unfiltered test',
        'refresh' => 30,
        'enable_deprecated_filtering' => true,
        'enable_deprecated_occurrence_filtering' => false
      },
      'occurrences' => 60,
      'action' => 'create'
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $CHILD_STATUS.exitstatus)
    refute_match(/#{occurrence_filter_deprecation_string}/, output)
  end
end
