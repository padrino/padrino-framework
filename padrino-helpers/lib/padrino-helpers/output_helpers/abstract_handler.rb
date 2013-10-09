module Padrino
  module Helpers
    module OutputHelpers
      ##
      # Returns the list of all available template handlers.
      #
      # @example
      #   OutputHelpers.handlers => [<OutputHelpers::HamlHandler>, <OutputHelpers::ErbHandler>]
      #
      def self.handlers
        @_template_handlers ||= {}
      end

      ##
      # Registers a new handler as available to the output helpers.
      #
      # @example
      #   OutputHelpers.register(OutputHelpers::HamlHandler)
      #
      def self.register(engine, handler)
        handlers[engine] = handler
      end

      # @abstract Extend this to create a template handler.
      class AbstractHandler
        attr_reader :template

        def initialize(template)
          @template = template
        end

        ##
        # Returns extension of the template.
        #
        # @example
        #   @handler.template_extension => "erb"
        #
        def template_extension
          caller.find { |c| c =~ /\/views\// }[/\.([\w]*?)\:/, 1] rescue nil
          # "/some/path/app/views/posts/foo.html.erb:3:in `evaluate_source'"
          # => "erb"
        end

        ##
        # Returns true if the block given is of the handler's template type; false otherwise.
        #
        # @example
        #   @handler.engine_matches?(block) => true
        #
        def engine_matches?(block)
          # Implemented in subclass.
        end

        ##
        # Captures the html from a block of template code for this handler.
        #
        # @example
        #   @handler.capture_from_template(&block) => "...html..."
        #
        def capture_from_template(*args, &block)
          # Implemented in subclass.
        end

        ##
        # Outputs the given text to the templates buffer directly.
        #
        # @example
        #   @handler.concat_to_template("This will be output to the template buffer")
        #
        def concat_to_template(text="")
          # Implemented in subclass.
        end
      end
    end
  end
end
