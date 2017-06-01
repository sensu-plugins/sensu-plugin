require 'test_helper'

class TestCheckExternal < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/check-options'
  end

  def test_ok
    run_script '-o'
    assert $?.exitstatus == 0
  end

  def test_warning
    run_script '-w'
    assert $?.exitstatus == 1
  end

  def test_critical
    run_script '-c'
    assert $?.exitstatus == 2
  end

  def test_unknown
    run_script '-u'
    assert $?.exitstatus == 3
  end

  def test_override
    output = run_script '-O'
    assert $?.exitstatus == 0 && !output.include?('argv =')
  end

  def test_config_from_settings
    ENV["SENSU_CHECK_NAME"] = "test1"
    ENV["SENSU_CONFIG_FILES"] = "test/external/config.json"
    output = run_script '-s'
    assert $?.exitstatus == 0 && output.include?("custom_value")
  end

  def test_fallthrough
    run_script
    assert $?.exitstatus == 1
  end

  def test_exception
    output = run_script '-f'
    assert $?.exitstatus == 3 && output.include?('failed')
  end

  def test_argv
    output = run_script '-o', 'foo'
    assert $?.exitstatus == 0 && output.include?('argv = foo')
  end

  def test_bad_commandline
    output = run_script '--doesnotexist'
    assert $?.exitstatus == 3 && output.include?('doesnotexist') && output.include?('invalid option')
  end

  def test_bad_require
    set_script 'external/bad-require' # TODO better way to switch scripts?
    output = run_script '2>&1'
    assert_equal($?.exitstatus, 3)
    assert_match(/LoadError/, output)
  end
end
