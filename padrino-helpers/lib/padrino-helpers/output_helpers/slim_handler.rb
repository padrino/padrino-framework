module Padrino
  module Helpers
    module OutputHelpers
      ##
      # Handler for reading and writing from a slim template.
      #
      class SlimHandler < AbstractHandler
        attr_reader :output_buffer

        def initialize(template)
          super
          @output_buffer = template.instance_variable_get(:@_out_buf)
        end

        ##
        # Captures the html from a block of template code for this handler.
        #
        # @example
        #   @handler.capture_from_template(&block) => "...html..."
        #
        def capture_from_template(*args, &block)
          self.output_buffer, _buf_was = ActiveSupport::SafeBuffer.new, self.output_buffer
          raw = block.call(*args)
          captured = template.instance_variable_get(:@_out_buf)
          self.output_buffer = _buf_was
          engine_matches?(block) ? captured : raw
        end

        ##
        # Outputs the given text to the templates buffer directly.
        #
        # @example
        #   @handler.concat_to_template("This will be output to the template buffer")
        #
        def concat_to_template(text="")
          self.output_buffer << text if text
          nil
        end

        ##
        # Returns true if the block given is of the handler's template type; false otherwise.
        #
        # @example
        #   @handler.engine_matches?(block) => true
        #
        def engine_matches?(block)
          block.binding.eval('defined? __in_slim_template')
        end

        protected

        def output_buffer=(val)
          template.instance_variable_set(:@_out_buf, val)
        end
      end
      OutputHelpers.register(:slim, SlimHandler)
    end
  end
end
