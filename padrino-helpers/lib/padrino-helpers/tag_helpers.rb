module Padrino
  module Helpers
    ##
    # Helpers related to producing html tags within templates.
    #
    module TagHelpers
      ##
      # Tag values escaped to html entities.
      #
      ESCAPE_VALUES = {
        '&' => '&amp;',
        '<' => '&lt;',
        '>' => '&gt;',
        '"' => '&quot;'
      }.freeze

      ##
      # Cached Regexp for escaping values to avoid rebuilding one
      # on every escape operation.
      #
      ESCAPE_REGEXP = Regexp.union(*ESCAPE_VALUES.keys).freeze

      BOOLEAN_ATTRIBUTES = %i[
        autoplay
        autofocus
        formnovalidate
        checked
        disabled
        hidden
        loop
        multiple
        muted
        readonly
        required
        selected
        declare
        defer
        ismap
        itemscope
        noresize
        novalidate
        allowfullscreen
        alpha
        async
        controls
        default
        headingreset
        inert
        nomodule
        open
        playsinline
        reversed
        shadowrootclonable
        shadowrootcustomelementregistry
        shadowrootdelegatesfocus
        shadowrootserializable
      ].freeze

      attribute_rules = ->(rule, names) { (names + names.map(&:to_s)).to_h { |name| [name, rule] } }
      false_value_attributes = %i[
        contenteditable draggable spellcheck writingsuggestions
        aria-atomic aria-busy aria-checked aria-current aria-disabled aria-expanded aria-grabbed aria-haspopup
        aria-hidden aria-invalid aria-modal aria-multiline aria-multiselectable aria-pressed aria-readonly
        aria-required aria-selected
      ]

      # How +tag_attributes+ writes a value, for the attributes that need more than escaping:
      # * boolean: +true+ writes the name (checked="checked"); a String or Symbol is kept (hidden="until-found").
      # * empty_value: enumerated attributes whose empty value is a state, so +true+ writes "" (popover="" is auto).
      # * false_value: attributes with a "false" keyword (HTML, and the WAI-ARIA true/false, tristate and
      #   token states), so +false+ is written rather than dropped.
      ATTRIBUTE_RULES = {
        **attribute_rules.call(:boolean, BOOLEAN_ATTRIBUTES),
        **attribute_rules.call(:class, %i[class]),
        **attribute_rules.call(:empty_value, %i[autocorrect crossorigin popover preload translate]),
        **attribute_rules.call(:false_value, false_value_attributes)
      }.freeze
      private_constant :ATTRIBUTE_RULES

      ##
      # Custom data attributes,
      # feel free to update with yours:
      #
      #   Padrino::Helpers::TagHelpers::DATA_ATTRIBUTES.push(:dialog)
      #   text_field :foo, dialog: true
      #   # Generates: <input type="text" data-dialog="true" name="foo" />
      #
      DATA_ATTRIBUTES = %i[method remote confirm]

      ##
      # A html_safe newline string to avoid allocating a new on each
      # concatenation.
      #
      NEWLINE = "\n".html_safe.freeze

      ##
      # The largest exponent, either way, of a BigDecimal written in plain decimal
      # notation; one beyond it is written in scientific notation ("0.1e1001"),
      # which writes the exponent as digits instead of writing out every zero.
      #
      PLAIN_DECIMAL_EXPONENT_LIMIT = 100
      private_constant :PLAIN_DECIMAL_EXPONENT_LIMIT

      ##
      # Whether the value is a BigDecimal.
      #
      # @api private
      def self.decimal?(value)
        defined?(::BigDecimal) && value.is_a?(::BigDecimal)
      end

      ##
      # Returns the text a value is written as in HTML: a finite BigDecimal in
      # its shortest exact plain decimal form (BigDecimal#to_s gives "0.999e1"
      # for 9.99, and to_s('F') gives "10.0" for 10), so it matches the text a
      # form sends back; anything else as its +to_s+.
      #
      # @example
      #   TagHelpers.value_to_s(BigDecimal('9.99')) # => "9.99"
      #   TagHelpers.value_to_s(BigDecimal('10'))   # => "10"
      #   TagHelpers.value_to_s(:price)             # => "price"
      #
      # @api private
      def self.value_to_s(value)
        return value.to_s unless decimal?(value)

        value.finite? && value.exponent.abs <= PLAIN_DECIMAL_EXPONENT_LIMIT ? value.to_s('F').delete_suffix('.0') : value.to_s('E')
      end

      ##
      # Whether two values are equal numbers, when either is a BigDecimal: the
      # other is read as a decimal from its text, so BigDecimal('10') equals
      # "10", "10.0", "10.00", 10 and 10.0. False for anything else.
      #
      # @api private
      def self.decimal_equal?(value, other)
        return false unless decimal?(value) || decimal?(other)

        value, other = [value, other].map { |item| decimal?(item) ? item : decimal_from(item.to_s) }
        value == other
      end

      ##
      # Reads the text as a BigDecimal, or returns nil when it is not a number.
      #
      def self.decimal_from(text)
        BigDecimal(text)
      rescue ArgumentError, TypeError, FloatDomainError
        nil
      end
      private_class_method :decimal_from

      ##
      # Creates an HTML tag with given name, content, and options.
      #
      # @overload content_tag(name, content, options = nil)
      #   @param [Symbol] name
      #     The name of the HTML tag to create.
      #   @param [String] content
      #     The content inside of the tag.
      #   @param [Hash] options
      #     The HTML options to include in this tag.
      #
      # @overload content_tag(name, options = nil, &block)
      #   @param [Symbol] name
      #     The name of the HTML tag to create.
      #   @param [Hash] options
      #     The HTML options to include in this tag.
      #   @param [Proc] block
      #     The block returning HTML content.
      #
      # @macro [new] global_html_attributes
      #   @option options [String] :id
      #     Specifies a unique identifier for the element.
      #   @option options [String] :class
      #     Specifies the stylesheet class of the element.
      #   @option options [String] :title
      #     Specifies the title for the element.
      #   @option options [String] :accesskey
      #     Specifies a shortcut key to access the element.
      #   @option options [Symbol] :dropzone
      #     Specifies what happens when dragged items are dropped on the element. (:copy, :link, :move)
      #   @option options [Boolean] :hidden
      #     Specifies whether or not the element is hidden from view.
      #   @option options [Boolean] :draggable
      #     Specifies whether or not the element is draggable. (true, false, :auto)
      #   @option options [Boolean] :contenteditable
      #     Specifies whether or not the element is editable.
      #
      # @return [String]
      #   Generated HTML with specified +options+.
      #
      # @example
      #   content_tag(:p, 'Hello World', class: 'light')
      #
      #   # => <p class="light">
      #   # =>   Hello World
      #   # => </p>
      #
      #   content_tag(:p, class: 'dark') do
      #     link_to 'Padrino', 'http://www.padrinorb.com'
      #   end
      #
      #   # => <p class="dark">
      #   # =>   <a href="http://www.padrinorb.com">Padrino</a>
      #   # => </p>
      #
      def content_tag(name, content = nil, options = nil, &block)
        if block_given?
          options = content if content.is_a?(Hash)
          content = capture_html(&block)
        end

        options    = parse_data_options(name, options)
        attributes = tag_attributes(options)
        output = SafeBuffer.new

        output.safe_concat "<#{name}#{attributes}>"
        if content.respond_to?(:each) && !content.is_a?(String)
          content.each do |item|
            output.concat TagHelpers.value_to_s(item)
            output.safe_concat NEWLINE
          end
        else
          output.concat TagHelpers.value_to_s(content)
        end
        output.safe_concat "</#{name}>"

        block_is_template?(block) ? concat_content(output) : output
      end

      ##
      # Like #content_tag, but assumes its input to be safe and doesn't
      # escape. It also returns safe HTML.
      #
      # @see #content_tag
      #
      def safe_content_tag(name, content = nil, options = nil, &block)
        mark_safe(content_tag(name, mark_safe(content), options, &block))
      end

      ##
      # Creates an HTML input field with the given type and options.
      #
      # @param [Symbol] type
      #   The type of input to create.
      # @param [Hash] options
      #   The HTML options to include in this input.
      #
      # @option options [String] :id
      #   Specifies a unique identifier for the input.
      # @option options [String] :class
      #   Specifies the stylesheet class of the input.
      # @option options [String] :name
      #   Specifies the name of the input.
      # @option options [String] :accesskey
      #   Specifies a shortcut key to access the input.
      # @option options [Integer] :tabindex
      #   Specifies the tab order of the input.
      # @option options [Boolean] :hidden
      #   Specifies whether or not the input is hidden from view.
      # @option options [Boolean] :spellcheck
      #   Specifies whether or not the input should have it's spelling and grammar checked for errors.
      # @option options [Boolean] :draggable
      #   Specifies whether or not the input is draggable. (true, false, :auto)
      # @option options [String] :pattern
      #   Specifies the regular expression pattern that the input's value is checked against.
      # @option options [Symbol] :autocomplete
      #   Specifies whether or not the input should have autocomplete enabled. (:on, :off)
      # @option options [Boolean] :autofocus
      #   Specifies whether or not the input should automatically get focus when the page loads.
      # @option options [Boolean] :required
      #   Specifies whether or not the input is required to be completed before the form is submitted.
      # @option options [Boolean] :readonly
      #   Specifies whether or not the input is read only.
      # @option options [Boolean] :disabled
      #   Specifies whether or not the input is disabled.
      #
      # @return [String]
      #   Generated HTML with specified +options+.
      #
      # @example
      #   input_tag :text, name: 'handle'
      #   # => <input type="test" name="handle" />
      #
      #   input_tag :password, name: 'password', size: 20
      #   # => <input type="password" name="password" size="20" />
      #
      #   input_tag :text, name: 'username', required: true, autofocus: true
      #   # => <input type="text" name="username" required autofocus />
      #
      #   input_tag :number, name: 'credit_card', autocomplete: :off
      #   # => <input type="number" name="credit_card" autocomplete="off" />
      #
      def input_tag(type, options = {})
        tag(:input, { type: type }.update(options))
      end

      ##
      # Creates an HTML tag with the given name and options.
      #
      # @param [Symbol] name
      #  The name of the HTML tag to create.
      # @param [Hash] options
      #  The HTML options to include in this tag.
      #
      # @macro global_html_attributes
      #
      # @return [String]
      #   Generated HTML with specified +options+.
      #
      # @example
      #   tag :hr, class: 'dotted'
      #   # => <hr class="dotted" />
      #
      #   tag :input, name: 'username', type: :text
      #   # => <input name="username" type="text" />
      #
      #   tag :img, src: 'images/pony.jpg', alt: 'My Little Pony'
      #   # => <img src="images/pony.jpg" alt="My Little Pony" />
      #
      #   tag :img, src: 'sinatra.jpg', data: { nsfw: false, geo: [34.087, -118.407] }
      #   # => <img src="sinatra.jpg" data-nsfw="false" data-geo="34.087 -118.407" />
      #
      #   tag :div, class: ['card', { active: true, hidden: false }], 'aria-hidden': false
      #   # => <div class="card active" aria-hidden="false" />
      #
      def tag(name, options = nil, open = false)
        options = parse_data_options(name, options)
        attributes = tag_attributes(options)
        "<#{name}#{attributes}#{open ? '>' : ' />'}".html_safe
      end

      ##
      # Builds a list of class names from Strings, Symbols, Arrays and Hashes.
      #
      # Strings are split on whitespace, Arrays are flattened, a Hash keeps the
      # keys whose values are truthy, and nil, false and blank names are left out.
      # Each name appears once, where it first appears. The result is a plain
      # String: +tag+ and +content_tag+ escape it when they write the attribute.
      #
      # @param [Array<String, Symbol, Array, Hash, nil, false>] args
      #   The class names, and the conditions that select them.
      #
      # @return [String]
      #   The class names, separated by spaces.
      #
      # @example
      #   class_names('btn', :primary)
      #   # => "btn primary"
      #
      #   class_names('card', active: true, disabled: false)
      #   # => "card active"
      #
      #   class_names('btn btn-lg', ['btn', [nil, { 'btn-block' => wide? }]])
      #   # => "btn btn-lg btn-block" (when wide? is truthy)
      #
      #   content_tag(:li, 'Home', class: class_names('nav-item', current: page == 'home'))
      #   # => <li class="nav-item current">Home</li>
      #
      def class_names(*args)
        class_name_tokens(args).uniq.join(' ')
      end

      SAFE_URI_SCHEMES = %w[http https mailto tel ftp].freeze

      ##
      # Returns an escaped document link.
      # Rejects unsafe URI schemes (javascript:, data:, vbscript:, etc.)
      # to prevent XSS via link injection.
      #
      # @example
      #   escape_link('http://example.com/spaced link')
      #   # => 'http://example.com/spaced%20link'
      #   escape_link('javascript:alert(1)')
      #   # => '#'
      #
      def escape_link(link)
        return link.gsub(' ', '%20') unless unsafe_uri_scheme?(link)

        '#'
      end

      ##
      # Returns true if the URI uses an unsafe scheme.
      #
      def unsafe_uri_scheme?(uri)
        return false unless uri

        # Read the scheme the way browsers do: drop tabs and newlines, skip leading
        # control characters and spaces, then take a run of scheme characters
        # followed by a colon. Relative links like 'search?q=a:b' have no scheme.
        # Everything is anchored at the start so long inputs are scanned once.
        scheme = uri.to_s.delete("\t\n\r")[/\A[\x00-\x20]*([a-z][a-z0-9+.-]*):/i, 1]
        return false unless scheme

        !SAFE_URI_SCHEMES.include?(scheme.downcase)
      end

      private

      ##
      # Returns a compiled list of HTML attributes.
      #
      def tag_attributes(options)
        return '' unless options

        all = +''
        options.each do |key, value|
          rule = ATTRIBUTE_RULES[key]
          case rule
          when :class then value = class_value(value) if value.is_a?(Array) || value.is_a?(Hash)
          when :empty_value then value = '' if value == true
          when :false_value then value = 'false' if value == false
          end
          next unless value

          all << ' ' if all.empty?
          all <<
            if value.is_a?(Hash)
              nested_values(key, value)
            elsif rule == :boolean && !value.is_a?(String) && !value.is_a?(Symbol)
              %(#{key}="#{key}" )
            else
              %(#{key}="#{escape_value(value)}" )
            end
        end
        all.chomp!(' ')
      end

      ##
      # Returns the class names in an Array, or a Hash of names to conditions,
      # leaving out blank names and those whose condition is false; nil if none are left.
      #
      def class_value(value)
        names = class_names_in(value)
        names unless names.empty?
      end

      def class_names_in(value)
        case value
        when Array then value.flat_map { |item| class_names_in(item) }
        when Hash then value.flat_map { |name, condition| condition ? class_names_in(name) : [] }
        else value && !value.to_s.empty? ? [value] : []
        end
      end

      ##
      # Escape tag values to their HTML/XML entities.
      #
      def escape_value(string)
        string = string.collect { |item| TagHelpers.value_to_s(item) }.join(' ') if string.is_a?(Array)
        string = TagHelpers.value_to_s(string)
        string.match?(ESCAPE_REGEXP) ? string.gsub(ESCAPE_REGEXP, ESCAPE_VALUES) : string
      end

      ##
      # Iterate through nested values.
      #
      def nested_values(attribute, hash)
        hash.inject(+'') do |all, (key, value)|
          attribute_with_name = "#{attribute}-#{key.to_s.tr('_', '-')}"
          all <<
            if value.is_a?(Hash)
              nested_values(attribute_with_name, value)
            else
              %(#{attribute_with_name}="#{escape_value(value)}" )
            end
        end
      end

      ##
      # Parses custom data attributes.
      #
      def parse_data_options(tag, options)
        return unless options
        return options unless DATA_ATTRIBUTES.any? { |key| options.key?(key) }

        parsed_options = options.dup
        options.each_key do |key|
          next if !DATA_ATTRIBUTES.include?(key) || (tag.to_s == 'form' && key == :method)
          parsed_options["data-#{key}"] = parsed_options.delete(key)
          parsed_options[:rel] = 'nofollow' if key == :method
        end
        parsed_options
      end

      ##
      # Returns the class names in a value given to #class_names, in order.
      #
      def class_name_tokens(value)
        case value
        when Array then value.flat_map { |item| class_name_tokens(item) }
        when Hash then value.flat_map { |name, condition| condition ? class_name_tokens(name) : [] }
        when nil, false then []
        else value.to_s.split(' ')
        end
      end
    end
  end
end
