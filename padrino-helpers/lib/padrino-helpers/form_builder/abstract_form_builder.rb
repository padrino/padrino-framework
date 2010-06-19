module Padrino
  module Helpers
    module FormBuilder #:nodoc:
      class AbstractFormBuilder #:nodoc:
        attr_accessor :template, :object

        def initialize(template, object)
          @template = template
          @object   = build_object(object)
          raise "FormBuilder template must be initialized!" unless template
          raise "FormBuilder object must be not be nil value. If there's no object, use a symbol instead! (i.e :user)" unless object
        end

        # f.error_messages
        def error_messages(*params)
          params.unshift object
          @template.error_messages_for(*params)
        end

        # f.error_message_on(field)
        def error_message_on(field, options={})
          @template.error_message_on(object_name, field, options)
        end

        # f.label :username, :caption => "Nickname"
        def label(field, options={})
          options.reverse_merge!(:caption => "#{field_human_name(field)}: ")
          @template.label_tag(field_id(field), options)
        end

        # f.hidden_field :session_id, :value => "45"
        def hidden_field(field, options={})
          options.reverse_merge!(:value => field_value(field), :id => field_id(field))
          @template.hidden_field_tag field_name(field), options
        end

        # f.text_field :username, :value => "(blank)", :id => 'username'
        def text_field(field, options={})
          options.reverse_merge!(:value => field_value(field), :id => field_id(field))
          options.merge!(:class => field_error(field, options))
          @template.text_field_tag field_name(field), options
        end

        # f.text_area :summary, :value => "(enter summary)", :id => 'summary'
        def text_area(field, options={})
          options.reverse_merge!(:value => field_value(field), :id => field_id(field))
          options.merge!(:class => field_error(field, options))
          @template.text_area_tag field_name(field), options
        end

        # f.password_field :password, :id => 'password'
        def password_field(field, options={})
          options.reverse_merge!(:value => field_value(field), :id => field_id(field))
          options.merge!(:class => field_error(field, options))
          @template.password_field_tag field_name(field), options
        end

        # f.select :color, :options => ['red', 'green'], :include_blank => true
        # f.select :color, :collection => @colors, :fields => [:name, :id]
        def select(field, options={})
          options.reverse_merge!(:id => field_id(field), :selected => field_value(field))
          options.merge!(:class => field_error(field, options))
          @template.select_tag field_name(field), options
        end

        # f.check_box :remember_me, :value => 'true', :uncheck_value => '0'
        def check_box(field, options={})
          unchecked_value = options.delete(:uncheck_value) || '0'
          options.reverse_merge!(:id => field_id(field), :value => '1')
          options.reverse_merge!(:checked => true) if values_matches_field?(field, options[:value])
          html  = @template.hidden_field_tag(options[:name] || field_name(field), :value => unchecked_value, :id => nil)
          html << @template.check_box_tag(field_name(field), options)
        end

        # f.radio_button :gender, :value => 'male'
        def radio_button(field, options={})
          options.reverse_merge!(:id => field_id(field, options[:value]))
          options.reverse_merge!(:checked => true) if values_matches_field?(field, options[:value])
          @template.radio_button_tag field_name(field), options
        end

        # f.file_field :photo, :class => 'avatar'
        def file_field(field, options={})
          options.reverse_merge!(:id => field_id(field))
          options.merge!(:class => field_error(field, options))
          @template.file_field_tag field_name(field), options
        end

        # f.submit "Update", :class => 'large'
        def submit(caption="Submit", options={})
          @template.submit_tag caption, options
        end

        # f.simage_submitubmit "buttons/submit.png", :class => 'large'
        def image_submit(source, options={})
          @template.image_submit_tag source, options
        end

        protected
          # Returns the known field types for a formbuilder
          def self.field_types
            [:hidden_field, :text_field, :text_area, :password_field, :file_field, :radio_button, :check_box, :select]
          end

          # Returns the object's models name
          #   => user_assignment
          def object_name
            object.is_a?(Symbol) ? object : object.class.to_s.underscore.gsub('/', '-')
          end

          # Returns true if the value matches the value in the field
          # field_has_value?(:gender, 'male')
          def values_matches_field?(field, value)
            value.present? && (field_value(field).to_s == value.to_s || field_value(field).to_s == 'true')
          end

          # Returns the value for the object's field
          # field_value(:username) => "Joey"
          def field_value(field)
            @object && @object.respond_to?(field) ? @object.send(field) : ""
          end

          # Add a :invalid css class to the field if it contain an error
          def field_error(field, options)
            error = @object.errors[field] rescue nil
            if error
              [options[:class], :invalid].flatten.compact.join(" ")
            else
              options[:class]
            end
          end

          # Returns the name for the given field
          # field_name(:username) => "user[username]"
          def field_name(field)
            "#{object_name}[#{field}]"
          end

          # Returns the human name of the field. Look that use builtin I18n.
          def field_human_name(field)
            I18n.translate("#{object_name}.attributes.#{field}", :count => 1, :default => field.to_s.humanize, :scope => :models)
          end

          # Returns the id for the given field
          # field_id(:username) => "user_username"
          # field_id(:gender, :male) => "user_gender_male"
          def field_id(field, value=nil)
            value.blank? ? "#{object_name}_#{field}" : "#{object_name}_#{field}_#{value}"
          end

          # explicit_object is either a symbol or a record
          # Returns a new record of the type specified in the object
          def build_object(object_or_symbol)
            object_or_symbol.is_a?(Symbol) ? @template.instance_variable_get("@#{object_or_symbol}") || object_class(object_or_symbol).new : object_or_symbol
          end

          # Returns the class type for the given object
          def object_class(explicit_object)
            explicit_object.is_a?(Symbol) ? explicit_object.to_s.camelize.constantize : explicit_object.class
          end
      end # AbstractFormBuilder
    end # FormBuilder
  end # Helpers
end # Padrino