module Padrino
  module Helpers
    module FormHelpers
      ##
      # Helpers to generate form errors.
      #
      module Errors
        ##
        # Constructs list HTML for the errors for a given symbol.
        #
        # @overload error_messages_for(*objects, options = {})
        #   @param [Array<Object>]  object   Splat of objects to display errors for.
        #   @param [Hash]           options  Error message display options.
        #   @option options [String] :header_tag ("h2")
        #     Used for the header of the error div.
        #   @option options [String] :id ("field-errors")
        #     The id of the error div.
        #   @option options [String] :class ("field-errors")
        #     The class of the error div.
        #   @option options [Array<Object>]  :object
        #     The object (or array of objects) for which to display errors,
        #     if you need to escape the instance variable convention.
        #   @option options [String] :object_name
        #     The object name to use in the header, or any text that you prefer.
        #     If +:object_name+ is not set, the name of the first object will be used.
        #   @option options [String] :header_message ("X errors prohibited this object from being saved")
        #     The message in the header of the error div. Pass +nil+ or an empty string
        #     to avoid the header message altogether.
        #   @option options [String] :message ("There were problems with the following fields:")
        #     The explanation message after the header message and before
        #     the error list.  Pass +nil+ or an empty string to avoid the explanation message
        #     altogether.
        #
        # @return [String] The html section with all errors for the specified +objects+
        #
        # @example
        #   error_messages_for :user
        #
        def error_messages_for(*objects)
          options = objects.last.is_a?(Hash) ? Utils.symbolize_keys(objects.pop) : {}
          objects = objects.map{ |obj| resolve_object(obj) }.compact
          count   = objects.inject(0){ |sum, object| sum + object.errors.count }
          return SafeBuffer.new if count.zero?

          content_tag(:div, error_contents(objects, count, options), error_html_attributes(options))
        end

        ##
        # Returns a string containing the error message attached to the
        # +method+ on the +object+ if one exists.
        #
        # @param [Object] object
        #   The object to display the error for.
        # @param [Symbol] field
        #   The field on the +object+ to display the error for.
        # @param [Hash] options
        #   The options to control the error display.
        # @option options [String] :tag ("span")
        #   The tag that encloses the error.
        # @option options [String] :prepend ("")
        #   The text to prepend before the field error.
        # @option options [String] :append ("")
        #   The text to append after the field error.
        #
        # @example
        #   # => <span class="error">can't be blank</div>
        #   error_message_on :post, :title
        #   error_message_on @post, :title
        #
        #   # => <div class="custom" style="border:1px solid red">can't be blank</div>
        #   error_message_on :post, :title, :tag => :id, :class => :custom, :style => "border:1px solid red"
        #
        #   # => <div class="error">This title can't be blank (or it won't work)</div>
        #   error_message_on :post, :title, :prepend => "This title", :append => "(or it won't work)"
        #
        # @return [String] The html display of an error for a particular +object+ and +field+.
        #
        # @api public
        def error_message_on(object, field, options={})
          error = Array(resolve_object(object).errors[field]).first
          return SafeBuffer.new unless error
          options = { :tag => :span, :class => :error }.update(options)
          tag   = options.delete(:tag)
          error = [options.delete(:prepend), error, options.delete(:append)].compact.join(" ")
          content_tag(tag, error, options)
        end

        private

        def error_contents(objects, count, options)
          object_name = options[:object_name] || Inflections.underscore(objects.first.class).gsub(/\//, ' ')

          contents = SafeBuffer.new
          contents << error_header_tag(options, object_name, count)
          contents << error_body_tag(options)
          contents << error_list_tag(objects, object_name)
        end

        def error_list_tag(objects, object_name)
          errors = objects.inject({}){ |all,object| all.update(object.errors) }
          error_messages = errors.inject(SafeBuffer.new) do |all, (field, message)|
            field_name = I18n.t(field, :default => Inflections.humanize(field), :scope => [:models, object_name, :attributes])
            all << content_tag(:li, "#{field_name} #{message}")
          end
          content_tag(:ul, error_messages)
        end

        def error_header_tag(options, object_name, count)
          header_message = options[:header_message] || begin
            model_name = I18n.t(:name, :default => Inflections.humanize(object_name), :scope => [:models, object_name], :count => 1)
            I18n.t :header, :count => count, :model => model_name, :locale => options[:locale], :scope => [:models, :errors, :template]
          end
          content_tag(options[:header_tag] || :h2, header_message) unless header_message.empty?
        end

        def error_body_tag(options)
          body_message = options[:message] || I18n.t(:body, :locale => options[:locale], :scope => [:models, :errors, :template])
          content_tag(:p, body_message) unless body_message.empty?
        end

        def error_html_attributes(options)
          [:id, :class, :style].each_with_object({}) do |key,all|
            if options.include?(key)
              value = options[key]
              all[key] = value if value
            else
              all[key] = 'field-errors' unless key == :style
            end
          end
        end

        def resolve_object(object)
          object.is_a?(Symbol) ? instance_variable_get("@#{object}") : object
        end
      end
    end
  end
end
