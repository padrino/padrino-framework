module Padrino
  module Helpers
    module OutputHelpers
      ##
      # Captures the html from a block of template code for erb or haml
      #
      # ==== Examples
      #
      #   capture_html(&block) => "...html..."
      #
      def capture_html(*args, &block)
        if self.respond_to?(:is_haml?) && is_haml?
          block_is_haml?(block) ? capture_haml(*args, &block) : block.call(*args)
        elsif has_erb_buffer?
          result_text = capture_erb(*args, &block)
          result_text.present? ? result_text : (block_given? && block.call(*args))
        else # theres no template to capture, invoke the block directly
          block.call(*args)
        end
      end

      ##
      # Outputs the given text to the templates buffer directly
      #
      # ==== Examples
      #
      #   concat_content("This will be output to the template buffer in erb or haml")
      #
      def concat_content(text="")
        if self.respond_to?(:is_haml?) && is_haml?
          haml_concat(text)
        elsif has_erb_buffer?
          erb_concat(text)
        else # theres no template to concat, return the text directly
          text
        end
      end

      ##
      # Returns true if the block is from an ERB or HAML template; false otherwise.
      # Used to determine if html should be returned or concatted to view
      #
      # ==== Examples
      #
      #   block_is_template?(block)
      #
      def block_is_template?(block)
        block && (block_is_erb?(block) || (self.respond_to?(:block_is_haml?) && block_is_haml?(block)))
      end

      ##
      # Capture a block or text of content to be rendered at a later time.
      # Your blocks can also receive values, which are passed to them by <tt>yield_content</tt>
      #
      # ==== Examples
      #
      #   content_for(:name) { ...content... }
      #   content_for(:name) { |name| ...content... }
      #   content_for(:name, "I'm Jeff")
      #
      def content_for(key, content = nil, &block)
        content_blocks[key.to_sym] << (block_given? ? block : Proc.new { content })
      end

      ##
      # Render the captured content blocks for a given key.
      # You can also pass values to the content blocks by passing them
      # as arguments after the key.
      #
      # ==== Examples
      #
      #   yield_content :include
      #   yield_content :head, "param1", "param2"
      #   yield_content(:title) || "My page title"
      #
      def yield_content(key, *args)
        blocks = content_blocks[key.to_sym]
        return nil if blocks.empty?
        blocks.map { |content|
          capture_html(*args, &content)
        }.join
      end

      private
        ##
        # Retrieves content_blocks stored by content_for or within yield_content
        #
        # ==== Examples
        #
        #   content_blocks[:name] => ['...', '...']
        #
        def content_blocks
          @content_blocks ||= Hash.new {|h,k| h[k] = [] }
        end

        ##
        # Used to capture the html from a block of erb code
        #
        # ==== Examples
        #
        #   capture_erb(&block) => '...html...'
        #
        def capture_erb(*args, &block)
          erb_with_output_buffer { block_given? && block.call(*args) }
        end

        ##
        # Concats directly to an erb template
        #
        # ==== Examples
        #
        #   erb_concat("Direct to buffer")
        #
        def erb_concat(text)
          @_out_buf << text if has_erb_buffer?
        end

        ##
        # Returns true if an erb buffer is detected
        #
        # ==== Examples
        #
        #   has_erb_buffer? => true
        #
        def has_erb_buffer?
          !@_out_buf.nil?
        end

        if RUBY_VERSION < '1.9.0'
          # Check whether we're called from an erb template.
          # We'd return a string in any other case, but erb <%= ... %>
          # can't take an <% end %> later on, so we have to use <% ... %>
          # and implicitly concat.
          def block_is_erb?(block)
            has_erb_buffer? || (block && eval('defined? __in_erb_template', block))
          end
        else
          def block_is_erb?(block)
            has_erb_buffer? || (block && eval('defined? __in_erb_template', block.binding))
          end
        end

        ##
        # Used to direct the buffer for the erb capture
        #
        def erb_with_output_buffer(buf = '')
          @_out_buf, old_buffer = buf, @_out_buf
          yield
          @_out_buf
        ensure
          @_out_buf = old_buffer
        end
    end # OutputHelpers
  end # Helpers
end # Padrino
