# frozen_string_literal: true

require 'test_helper'
require 'sensu-plugin/utils'

class TestCastBoolInt < MiniTest::Test
  include SensuPluginTestHelper
  include Sensu::Plugin::Utils

  def test_integer
    assert_equal 567.89, cast_bool_values_int(567.89)
  end

  def test_false_boolean
    assert_equal 0, cast_bool_values_int(false)
  end

  def test_true_boolean
    assert_equal 1, cast_bool_values_int(true)
  end

  def test_false_string
    assert_equal 0, cast_bool_values_int('false')
  end

  def test_true_string
    assert_equal 1, cast_bool_values_int('true')
  end

  def test_arbirtrary_string
    assert_equal 'foo', cast_bool_values_int('foo')
  end
end
