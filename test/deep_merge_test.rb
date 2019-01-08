# frozen_string_literal: true

require 'test_helper'
require 'sensu-plugin/utils'

class TestDeepMerge < MiniTest::Test
  include SensuPluginTestHelper
  include Sensu::Plugin::Utils

  def test_hash
    merged = deep_merge({ a: 'a' }, b: 'b')
    assert(merged == { a: 'a', b: 'b' })
  end

  def test_nested_hash
    merged = deep_merge({ a: { b: 'c' } }, a: { d: 'e' })
    assert(merged == { a: { b: 'c', d: 'e' } })
  end

  def test_nested_array
    merged = deep_merge({ a: ['b'] }, a: ['c'])
    assert(merged, a: %w[b c])
  end

  def test_conflicting_types
    merged = deep_merge({ a: { b: 'c' } }, a: ['d'])
    assert(merged, a: { b: 'c' })
  end
end
