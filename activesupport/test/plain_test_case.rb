# frozen_string_literal: true

require "minitest/mock"
require "active_support/testing/assertions"
require "active_support/testing/alternative_runtime_skipper"
require "active_support/testing/declarative"
require "active_support/testing/isolation"
require "active_support/testing/method_call_assertions"

module ActiveSupport
  # A TestCase base class that is not polluted by Active Support modules.
  # It's better to use this class for testing Active Support features so we can isolate the problems.
  class PlainTestCase < ::Minitest::Test
    Assertion = Minitest::Assertion

    alias_method :method_name, :name

    # test/unit backwards compatibility methods
    alias :assert_raise :assert_raises
    alias :assert_not_empty :refute_empty
    alias :assert_not_equal :refute_equal
    alias :assert_not_in_delta :refute_in_delta
    alias :assert_not_in_epsilon :refute_in_epsilon
    alias :assert_not_includes :refute_includes
    alias :assert_not_instance_of :refute_instance_of
    alias :assert_not_kind_of :refute_kind_of
    alias :assert_no_match :refute_match
    alias :assert_not_nil :refute_nil
    alias :assert_not_operator :refute_operator
    alias :assert_not_predicate :refute_predicate
    alias :assert_not_respond_to :refute_respond_to
    alias :assert_not_same :refute_same

    # very limited set of ActiveSupport::Testing utilities that we can't live without
    include ActiveSupport::Testing::Assertions
    include ActiveSupport::Testing::AlternativeRuntimeSkipper
    extend ActiveSupport::Testing::Declarative
    include ActiveSupport::Testing::MethodCallAssertions
  end
end
