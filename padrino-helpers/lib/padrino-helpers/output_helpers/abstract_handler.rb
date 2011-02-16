module Padrino
  module Helpers

    module OutputHelpers
      @template_handlers = []

      ##
      # Returns the list of all available template handlers
      #
      # ==== Examples
      #
      #   OutputHelpers.handlers => [<OutputHelpers::HamlHandler>, <OutputHelpers::ErbHandler>]
      #
      def self.handlers
        @template_handlers
      end

      ##
      # Registers a new handler as available to the output helpers
      #
      # ==== Examples
      #
      #   OutputHelpers.register(OutputHelpers::HamlHandler)
      #
      def self.register(handler)
        handlers << handler
      end

      class AbstractHandler
        attr_reader :template

        def initialize(template)
          @template = template
        end

        ##
        # Returns true if the current template type is same as this handlers; false otherwise.
        #
        # ==== Examples
        #
        #  @handler.is_type? => true
        #
        def is_type?
          # Implemented in subclass
        end

        ##
        # Returns true if the block given is of the handler's template type; false otherwise.
        #
        # ==== Examples
        #
        #  @handler.block_is_type?(block) => true
        #
        def block_is_type?(block)
          # Implemented in subclass
        end

        ##
        # Captures the html from a block of template code for this handler
        #
        # ==== Examples
        #
        #  @handler.capture_from_template(&block) => "...html..."
        #
        def capture_from_template(*args, &block)
          # Implemented in subclass
        end

        ##
        # Outputs the given text to the templates buffer directly
        #
        # ==== Examples
        #
        #   @handler.concat_to_template("This will be output to the template buffer")
        #
        def concat_to_template(text="")
          # Implemented in subclass
        end
      end # AbstractHandler
    end # OutputHelpers

  end
end
