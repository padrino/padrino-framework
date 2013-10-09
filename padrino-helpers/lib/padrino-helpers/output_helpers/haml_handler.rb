module Padrino
  module Helpers
    module OutputHelpers
      ##
      # Handler for reading and writing from a haml template.
      #
      class HamlHandler < AbstractHandler
        ##
        # Returns true if the block given is of the handler's template type; false otherwise.
        #
        # @example
        #   @handler.engine_matches?(block) => true
        #
        def engine_matches?(block)
          template.block_is_haml?(block)
        end

        ##
        # Captures the html from a block of template code for this handler.
        #
        # @example
        #   @handler.capture_from_template(&block) => "...html..."
        #
        def capture_from_template(*args, &block)
          engine_matches?(block) ? template.capture_haml(*args, &block) : block.call(*args)
        end

        ##
        # Outputs the given text to the templates buffer directly.
        #
        # @example
        #   @handler.concat_to_template("This will be output to the template buffer")
        #
        def concat_to_template(text="")
          template.haml_concat(text)
          nil
        end
      end
      OutputHelpers.register(:haml, HamlHandler)
    end
  end
end
