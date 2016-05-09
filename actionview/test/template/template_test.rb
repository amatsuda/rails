# frozen_string_literal: true

require "abstract_unit"
require "logger"

class TestERBTemplate < ActiveSupport::TestCase
  ERBHandler = ActionView::Template::Handlers::ERB.new

  class LookupContext
    def disable_cache
      yield
    end

    def find_template(*args)
    end

    attr_accessor :formats
  end

  class Context
    def initialize
      @output_buffer = "original"
      @virtual_path = nil
    end

    def hello
      "Hello"
    end

    def apostrophe
      "l'apostrophe"
    end

    def partial
      ActionView::Template.new(
        "<%= @virtual_path %>",
        "partial",
        ERBHandler,
        virtual_path: "partial"
      )
    end

    def lookup_context
      @lookup_context ||= LookupContext.new
    end

    def logger
      ActiveSupport::Logger.new(STDERR)
    end

    def my_buffer
      @output_buffer
    end
  end

  def new_template(body = "<%= hello %>", details = { format: :html })
    ActionView::Template.new(body.dup, "hello template", details.fetch(:handler) { ERBHandler }, { virtual_path: "hello" }.merge!(details))
  end

  def render(locals = {})
    @template.render(@context, locals)
  end

  def setup
    @context = Context.new
  end

  def test_basic_template
    @template = new_template
    assert_equal "Hello", render
  end

  def test_basic_template_does_html_escape
    @template = new_template("<%= apostrophe %>")
    assert_equal "l&#39;apostrophe", render
  end

  def test_text_template_does_not_html_escape
    @template = new_template("<%= apostrophe %> <%== apostrophe %>", format: :text)
    assert_equal "l'apostrophe l'apostrophe", render
  end

  def test_raw_template
    @template = new_template("<%= hello %>", handler: ActionView::Template::Handlers::Raw.new)
    assert_equal "<%= hello %>", render
  end

  def test_template_loses_its_source_after_rendering
    @template = new_template
    render
    assert_nil @template.source
  end

  def test_template_does_not_lose_its_source_after_rendering_if_it_does_not_have_a_virtual_path
    @template = new_template("Hello", virtual_path: nil)
    render
    assert_equal "Hello", @template.source
  end

  def test_locals
    @template = new_template("<%= my_local %>")
    @template.locals = [:my_local]
    assert_equal "I am a local", render(my_local: "I am a local")
  end

  def test_restores_buffer
    @template = new_template
    assert_equal "Hello", render
    assert_equal "original", @context.my_buffer
  end

  def test_virtual_path
    @template = new_template("<%= @virtual_path %>" \
                             "<%= partial.render(self, {}) %>" \
                             "<%= @virtual_path %>")
    assert_equal "hellopartialhello", render
  end

  def test_refresh_with_templates
    @template = new_template("Hello", virtual_path: "test/foo/bar")
    @template.locals = [:key]
    assert_called_with(@context.lookup_context, :find_template, ["bar", %w(test/foo), false, [:key]], returns: "template") do
      assert_equal "template", @template.refresh(@context)
    end
  end

  def test_refresh_with_partials
    @template = new_template("Hello", virtual_path: "test/_foo")
    @template.locals = [:key]
    assert_called_with(@context.lookup_context, :find_template, ["foo", %w(test), true, [:key]], returns: "partial") do
      assert_equal "partial", @template.refresh(@context)
    end
  end

  def test_refresh_raises_an_error_without_virtual_path
    @template = new_template("Hello", virtual_path: nil)
    assert_raise RuntimeError do
      @template.refresh(@context)
    end
  end

  def test_resulting_string_is_utf8
    @template = new_template
    assert_equal Encoding::UTF_8, render.encoding
  end

  def test_no_magic_comment_word_with_utf_8
    @template = new_template("hello \u{fc}mlat")
    assert_equal Encoding::UTF_8, render.encoding
    assert_equal "hello \u{fc}mlat", render
  end
end
