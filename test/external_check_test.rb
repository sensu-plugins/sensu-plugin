# frozen_string_literal: true

require 'test_helper'
require 'English'

class TestCheckExternal < MiniTest::Test
  include SensuPluginTestHelper

  def setup
    set_script 'external/check-options'
  end

  def test_ok
    run_script '-o'
    assert $CHILD_STATUS.success?
  end

  def test_warning
    run_script '-w'
    assert $CHILD_STATUS.exitstatus == 1
  end

  def test_critical
    run_script '-c'
    assert $CHILD_STATUS.exitstatus == 2
  end

  def test_unknown
    run_script '-u'
    assert $CHILD_STATUS.exitstatus == 3
  end

  def test_override
    output = run_script '-O'
    assert $CHILD_STATUS.success? && !output.include?('argv =')
  end

  def test_fallthrough
    run_script
    assert $CHILD_STATUS.exitstatus == 1
  end

  def test_exception
    output = run_script '-f'
    assert $CHILD_STATUS.exitstatus == 3 && output.include?('failed')
  end

  def test_argv
    output = run_script '-o', 'foo'
    assert $CHILD_STATUS.success? && output.include?('argv = foo')
  end

  def test_bad_commandline
    output = run_script '--doesnotexist'
    assert $CHILD_STATUS.exitstatus == 3 && output.include?('doesnotexist') && output.include?('invalid option')
  end

  def test_bad_require
    set_script 'external/bad-require' # TODO: better way to switch scripts?
    output = run_script '2>&1'
    assert_equal($CHILD_STATUS.exitstatus, 3)
    assert_match(/LoadError/, output)
  end
end
