module Padrino
  module Helpers

    module OutputHelpers
      class ErbHandler < AbstractHandler
        attr_reader :output_buffer

        def initialize(template)
          super
          @output_buffer = template.instance_variable_get(:@_out_buf)
        end

        ##
        # Returns true if the current template type is same as this handlers; false otherwise.
        #
        # ==== Examples
        #
        #  @handler.is_type? => true
        #
        def is_type?
          self.output_buffer.present?
        end

        # Captures the html from a block of template code for this handler
        #
        # ==== Examples
        #
        #  @handler.capture_from_template(&block) => "...html..."
        #
        def capture_from_template(*args, &block)
          erb_with_output_buffer { block_given? && block.call(*args) }
        end

        ##
        # Outputs the given text to the templates buffer directly
        #
        # ==== Examples
        #
        #   @handler.concat_to_template("This will be output to the template buffer")
        #
        def concat_to_template(text="")
          self.output_buffer << text if self.is_type? && text
          nil
        end

        if RUBY_VERSION < '1.9.0'
          # Check whether we're called from an erb template.
          # We'd return a string in any other case, but erb <%= ... %>
          # can't take an <% end %> later on, so we have to use <% ... %>
          # and implicitly concat.
          def block_is_type?(block)
            self.is_type? || (block && eval('defined? __in_erb_template', block))
          end
        else
          def block_is_type?(block)
            self.is_type? || (block && eval('defined? __in_erb_template', block.binding))
          end
        end

        protected

        ##
        # Used to direct the buffer for the erb capture
        #
        def erb_with_output_buffer(buf = '')
          self.output_buffer, old_buffer = buf, self.output_buffer
          yield
          buf
        ensure
          self.output_buffer = old_buffer
        end

        def output_buffer=(val)
          template.instance_variable_set(:@_out_buf, val)
        end
      end # ErbHandler
      OutputHelpers.register(ErbHandler)
    end # OutputHelpers
  end
end