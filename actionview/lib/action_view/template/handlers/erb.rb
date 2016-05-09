# frozen_string_literal: true

module ActionView
  class Template
    module Handlers
      class ERB
        autoload :Erubi, "action_view/template/handlers/erb/erubi"

        # Specify trim mode for the ERB compiler. Defaults to '-'.
        # See ERB documentation for suitable values.
        class_attribute :erb_trim_mode, default: "-"

        # Default implementation used.
        class_attribute :erb_implementation, default: Erubi

        # Do not escape templates of these mime types.
        class_attribute :escape_whitelist, default: ["text/plain"]

        def self.call(template)
          new.call(template)
        end

        def supports_streaming?
          true
        end

        def call(template)
          erb = template.source

          raise WrongEncodingError.new(erb, Encoding.default_internal) unless erb.valid_encoding?

          self.class.erb_implementation.new(
            erb,
            escape: (self.class.escape_whitelist.include? template.type),
            trim: (self.class.erb_trim_mode == "-")
          ).src
        end
      end
    end
  end
end
