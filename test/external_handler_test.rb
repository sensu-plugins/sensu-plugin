require 'rubygems'
require 'minitest/autorun'
require 'json'
require 'time'

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

class TestHandlerExternalWithFilter < MiniTest::Unit::TestCase
  include SensuPluginTestHelper

  def setup
    set_script 'external/handle-subdue'
  end

  def test_subdued
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
      'subdue' => {
        'start' => (Time.now - 3600).strftime('%l:00 %P').strip,
        'end' => (Time.now + 3600).strftime('%l:00 %P').strip
      }
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/subdue/, output)
  end

  def test_nonsubdued
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
      'subdue' => {
        'start' => (Time.now + 3600).strftime('%l:00 %P').strip,
        'end' => (Time.now + 7200).strftime('%l:00 %P').strip
      }
    }
    output = run_script_with_input(JSON.generate(event))
    assert $?.exitstatus == 0 && output =~ /Event:/
  end

  def test_wrapped_subdued
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
      'subdue' => {
        'start' => (Time.now - 3600).strftime('%l:00 %P').strip,
        'end' => (Time.now - 7200).strftime('%l:00 %P').strip
      }
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/subdue/, output)
  end

  def test_wrapped_nonsubdued
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
      'subdue' => {
        'start' => (Time.now + 3600).strftime('%l:00 %P').strip,
        'end' => (Time.now - 7200).strftime('%l:00 %P').strip
      }
    }
    output = run_script_with_input(JSON.generate(event))
    assert $?.exitstatus == 0 && output =~ /Event:/
  end

  def test_day_subdued
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
      'subdue' => {
        'days' => Time.now.strftime('%A')
      }
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/subdue/, output)
  end

  def test_days_subdued
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
      'subdue' => {
        'days' => [Time.now.strftime('%A'), 'Monday']
      }
    }
    output = run_script_with_input(JSON.generate(event))
    assert_equal(0, $?.exitstatus)
    assert_match(/subdue/, output)
  end

  def test_day_nonsubdued
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
      'subdue' => {
        'days' => (Time.now + 86400).strftime('%A')
      }
    }
    output = run_script_with_input(JSON.generate(event))
    assert $?.exitstatus == 0 && output =~ /Event:/
  end

  def test_days_nonsubdued
    event = {
      'client' => { 'name' => 'test' },
      'check' => { 'name' => 'test' },
      'occurrences' => 1,
      'subdue' => {
        'days' => [
          (Time.now + 86400).strftime('%A'),
          (Time.now + 172800).strftime('%A')
        ]
      }
    }
    output = run_script_with_input(JSON.generate(event))
    assert $?.exitstatus == 0 && output =~ /Event:/
  end

  def test_missing_keys
    event = {}
    output = run_script_with_input(JSON.generate(event))
    assert $?.exitstatus == 0 && output =~ /Event:/
  end

end
