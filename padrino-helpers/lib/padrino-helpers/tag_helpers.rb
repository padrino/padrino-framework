module Padrino
  module Helpers
    ##
    # Helpers related to producing html tags within templates.
    #
    module TagHelpers
      ##
      # Tag values escaped to html entities
      #
      ESCAPE_VALUES = {
        "<" => "&lt;",
        ">" => "&gt;",
        '"' => "&quot;"
      }

      BOOLEAN_ATTRIBUTES = [
        :autoplay,
        :autofocus,
        :autobuffer,
        :checked,
        :disabled,
        :hidden,
        :loop,
        :multiple,
        :muted,
        :readonly,
        :required,
        :selected,
      ]

      ##
      # Creates an html tag with given name, content and options
      #
      # @overload content_tag(name, content, options)
      #   @param [Symbol]  name     The html type of tag.
      #   @param [String]  content  The contents in the tag.
      #   @param [Hash]    options  The html options to include in this tag.
      # @overload content_tag(name, options, &block)
      #   @param [Symbol]  name     The html type of tag.
      #   @param [Hash]    options  The html options to include in this tag.
      #   @param [Proc]    block    The block returning html content
      #
      # @return [String] The html generated for the tag.
      #
      # @example
      #   content_tag(:p, "hello", :class => 'light')
      #   content_tag(:p, :class => 'dark') { ... }
      #
      # @api public
      def content_tag(name, content = nil, options = nil, &block)
        if block_given?
          options = content if content.is_a?(Hash)
          content = capture_html(&block)
        end

        content = content.join("\n") if content.respond_to?(:join)

        output = "<#{name}#{tag_options(options) if options}>#{content}</#{name}>"
        block_is_template?(block) ? concat_content(output) : output
      end

      ##
      # Creates an html input field with given type and options
      #
      # @param [Symbol] type
      #   The html type of tag to create.
      # @param [Hash] options
      #   The html options to include in this tag.
      #
      # @return [String] The html for the input tag.
      #
      # @example
      #   input_tag :text, :class => "test"
      #   input_tag :password, :size => "20"
      #
      # @api semipublic
      def input_tag(type, options = {})
        options.reverse_merge!(:type => type)
        tag(:input, options)
      end

      ##
      # Creates an html tag with the given name and options
      #
      # @param [Symbol] type
      #   The html type of tag to create.
      # @param [Hash] options
      #   The html options to include in this tag.
      #
      # @return [String] The html for the input tag.
      #
      # @example
      #   tag(:br, :style => 'clear:both')
      #
      # @api public
      def tag(name, options = nil, open = false)
        "<#{name}#{tag_options(options) if options}#{open ? '>' : ' />'}"
      end

      private
        ##
        # Returns a compiled list of HTML attributes
        #
        def tag_options(options)
          unless options.blank?
            attributes = []
            options.each do |attribute, value|
              next if value.nil? || value == false
              value = attribute if BOOLEAN_ATTRIBUTES.include?(attribute)
              if attribute == :data && value.is_a?(Hash)
                value.each { |k, v| attributes << %[data-#{k.to_s.dasherize}="#{escape_value(v)}"] }
              else
                attributes << %[#{attribute}="#{escape_value(value)}"]
              end
            end
            " #{attributes.join(' ')}"
          end
        end

        ##
        # Escape tag values to their HTML/XML entities.
        #
        def escape_value(string)
          string.to_s.gsub(Regexp.union(*ESCAPE_VALUES.keys)){|c| ESCAPE_VALUES[c] }
        end
    end # TagHelpers
  end # Helpers
end # Padrino
