# frozen_string_literal: true

require "active_support/core_ext/object/try"
require "active_support/core_ext/kernel/singleton_class"
require "thread"

module ActionView
  # = Action View Template
  class Template
    extend ActiveSupport::Autoload

    ##
    # :method: local_assigns
    #
    # Returns a hash with the defined local variables.
    #
    # Given this sub template rendering:
    #
    #   <%= render "shared/header", { headline: "Welcome", person: person } %>
    #
    # You can use +local_assigns+ in the sub templates to access the local variables:
    #
    #   local_assigns[:headline] # => "Welcome"

    eager_autoload do
      autoload :Error
      autoload :Handlers
      autoload :HTML
      autoload :Text
      autoload :Types
    end

    extend Template::Handlers

    attr_accessor :locals, :formats, :variants, :virtual_path

    attr_reader :source, :identifier, :handler, :updated_at

    # This finalizer is needed (and exactly with a proc inside another proc)
    # otherwise templates leak in development.
    Finalizer = proc do |method_name, mod| # :nodoc:
      proc do
        mod.module_eval do
          remove_possible_method method_name
        end
      end
    end

    def initialize(source, identifier, handler, details)
      format = details[:format] || (handler.default_format if handler.respond_to?(:default_format))

      @source            = source
      @identifier        = identifier
      @handler           = handler
      @compiled          = false
      @locals            = details[:locals] || []
      @virtual_path      = details[:virtual_path]
      @updated_at        = details[:updated_at] || Time.now
      @formats           = Array(format).map { |f| f.respond_to?(:ref) ? f.ref : f  }
      @variants          = [details[:variant]]
      @compile_mutex     = Mutex.new
    end

    # Returns whether the underlying handler supports streaming. If so,
    # a streaming buffer *may* be passed when it starts rendering.
    def supports_streaming?
      handler.respond_to?(:supports_streaming?) && handler.supports_streaming?
    end

    # Render a template. If the template was not compiled yet, it is done
    # exactly before rendering.
    #
    # This method is instrumented as "!render_template.action_view". Notice that
    # we use a bang in this instrumentation because you don't want to
    # consume this in production. This is only slow if it's being listened to.
    def render(view, locals, buffer = nil, &block)
      instrument_render_template do
        compile!(view)
        view.send(method_name, locals, buffer, &block)
      end
    rescue => e
      handle_render_error(view, e)
    end

    def type
      @type ||= Types[@formats.first] if @formats.first
    end

    # Receives a view object and return a template similar to self by using @virtual_path.
    #
    # This method is useful if you have a template object but it does not contain its source
    # anymore since it was already compiled. In such cases, all you need to do is to call
    # refresh passing in the view object.
    #
    # Notice this method raises an error if the template to be refreshed does not have a
    # virtual path set (true just for inline templates).
    def refresh(view)
      raise "A template needs to have a virtual path in order to be refreshed" unless @virtual_path
      lookup  = view.lookup_context
      pieces  = @virtual_path.split("/")
      name    = pieces.pop
      partial = !!name.sub!(/^_/, "")
      lookup.disable_cache do
        lookup.find_template(name, [ pieces.join("/") ], partial, @locals)
      end
    end

    def inspect
      @inspect ||= defined?(Rails.root) ? identifier.sub("#{Rails.root}/", "".freeze) : identifier
    end

    private

      # Compile a template. This method ensures a template is compiled
      # just once and removes the source after it is compiled.
      def compile!(view)
        return if @compiled

        # Templates can be used concurrently in threaded environments
        # so compilation and any instance variable modification must
        # be synchronized
        @compile_mutex.synchronize do
          # Any thread holding this lock will be compiling the template needed
          # by the threads waiting. So re-check the @compiled flag to avoid
          # re-compilation
          return if @compiled

          if view.is_a?(ActionView::CompiledTemplates)
            mod = ActionView::CompiledTemplates
          else
            mod = view.singleton_class
          end

          instrument("!compile_template") do
            compile(mod)
          end

          # Just discard the source if we have a virtual path. This
          # means we can get the template back.
          @source = nil if @virtual_path
          @compiled = true
        end
      end

      def compile(mod)
        code = @handler.call(self)

        source = <<-end_src.dup
          def #{method_name}(local_assigns, output_buffer)
            _old_virtual_path, @virtual_path = @virtual_path, #{@virtual_path.inspect};_old_output_buffer = @output_buffer;#{locals_code};#{code}
          ensure
            @virtual_path, @output_buffer = _old_virtual_path, _old_output_buffer
          end
        end_src

        unless source.valid_encoding?
          raise WrongEncodingError.new(@source, Encoding.default_internal)
        end

        mod.module_eval(source, identifier, 0)
        ObjectSpace.define_finalizer(self, Finalizer[method_name, mod])
      end

      def handle_render_error(view, e)
        if e.is_a?(Template::Error)
          e.sub_template_of(self)
          raise e
        else
          template = self
          unless template.source
            template = refresh(view)
          end
          raise Template::Error.new(template)
        end
      end

      def locals_code
        # Only locals with valid variable names get set directly. Others will
        # still be available in local_assigns.
        locals = @locals - Module::RUBY_RESERVED_KEYWORDS
        locals = locals.grep(/\A@?(?![A-Z0-9])(?:[[:alnum:]_]|[^\0-\177])+\z/)

        # Assign for the same variable is to suppress unused variable warning
        locals.each_with_object("".dup) { |key, code| code << "#{key} = local_assigns[:#{key}]; #{key} = #{key};" }
      end

      def method_name
        @method_name ||= begin
          m = "_#{identifier_method_name}__#{@identifier.hash}_#{__id__}".dup
          m.tr!("-".freeze, "_".freeze)
          m
        end
      end

      def identifier_method_name
        inspect.tr("^a-z_".freeze, "_".freeze)
      end

      def instrument(action, &block) # :doc:
        ActiveSupport::Notifications.instrument("#{action}.action_view", instrument_payload, &block)
      end

      def instrument_render_template(&block)
        ActiveSupport::Notifications.instrument("!render_template.action_view".freeze, instrument_payload, &block)
      end

      def instrument_payload
        { virtual_path: @virtual_path, identifier: @identifier }
      end
  end
end
