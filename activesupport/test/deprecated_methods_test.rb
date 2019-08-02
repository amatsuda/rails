# frozen_string_literal: true

require "abstract_unit"
require "active_support/core_ext/module/introspection"
require "multibyte_test_helpers"

module ParentA
  module B
  end
end

class DeprecatedMethodsTest < ActiveSupport::TestCase
  def test_requiring_array_prepend_and_append_is_deprecated
    assert_deprecated do
      require "active_support/core_ext/array/prepend_and_append"
    end
  end
  def test_requiring_hash_compact_is_deprecated
    assert_deprecated do
      require "active_support/core_ext/hash/compact"
    end
  end

  test "requiring Hash#transform_values is deprecated" do
    assert_deprecated do
      require "active_support/core_ext/hash/transform_values"
    end
  end

  def test_requiring_numeric_inquiry_is_deprecated
    assert_deprecated do
      require "active_support/core_ext/numeric/inquiry"
    end
  end

  def test_module_parent_name_is_deprecated
    assert_deprecated do
      assert_equal "ParentA", ParentA::B.parent_name
    end
  end

  def test_module_parent_is_deprecated
    assert_deprecated do
      assert_equal ParentA, ParentA::B.parent
    end
  end

  def test_module_parents_is_deprecated
    assert_deprecated do
      assert_equal [ParentA, Object], ParentA::B.parents
    end
  end

  test "Including top constant LoggerSilence is deprecated" do
    assert_deprecated("Please use `ActiveSupport::LoggerSilence`") do
      Class.new do
        include ::LoggerSilence
      end
    end
  end

  def test_multibyte_chars_consumes_is_deprecated
    assert_deprecated { ActiveSupport::Multibyte::Chars.consumes?(MultibyteTestHelpers::UNICODE_STRING) }
  end

  def test_multibyte_chars_unicode_normalize_deprecation
    # String#unicode_normalize default form is `:nfc`, and
    # different than Multibyte::Unicode default, `:nkfc`.
    # Deprecation should suggest the right form if no params
    # are given and default is used.
    assert_deprecated(/unicode_normalize\(:nfkc\)/) do
      ActiveSupport::Multibyte::Unicode.normalize("")
    end

    assert_deprecated(/unicode_normalize\(:nfd\)/) do
      ActiveSupport::Multibyte::Unicode.normalize("", :d)
    end
  end

  def test_multibyte_chars_normalize_deprecation
    # String#unicode_normalize default form is `:nfc`, and
    # different than Multibyte::Unicode default, `:nkfc`.
    # Deprecation should suggest the right form if no params
    # are given and default is used.
    assert_deprecated(/unicode_normalize\(:nfkc\)/) do
      "".mb_chars.normalize
    end

    assert_deprecated(/unicode_normalize\(:nfc\)/) { "".mb_chars.normalize(:c) }
    assert_deprecated(/unicode_normalize\(:nfd\)/) { "".mb_chars.normalize(:d) }
    assert_deprecated(/unicode_normalize\(:nfkc\)/) { "".mb_chars.normalize(:kc) }
    assert_deprecated(/unicode_normalize\(:nfkd\)/) { "".mb_chars.normalize(:kd) }
  end

  def test_multibyte_unicode_deprecations
    assert_deprecated { ActiveSupport::Multibyte::Unicode.downcase("") }
    assert_deprecated { ActiveSupport::Multibyte::Unicode.upcase("") }
    assert_deprecated { ActiveSupport::Multibyte::Unicode.swapcase("") }
  end
end
