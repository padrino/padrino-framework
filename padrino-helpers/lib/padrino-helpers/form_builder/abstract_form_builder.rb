module Padrino
  module Helpers
    module FormBuilder
      # Base class for Padrino Form Builder
      class AbstractFormBuilder
        attr_accessor :template, :object, :multipart
        attr_reader :namespace, :is_nested, :parent_form, :nested_index, :attributes_name, :model_name

        def initialize(template, object, options={})
          @template = template
          fail "FormBuilder template must be initialized" unless template
          @object = object.kind_of?(Symbol) ? build_object(object) : object
          fail "FormBuilder object must be present. If there's no object, use a symbol instead (i.e. :user)" unless object
          @options = options
          @namespace = options[:namespace]
          @model_name = options[:as] || Inflections.underscore(@object.class).tr('/', '_')
          nested = options[:nested]
          if @is_nested = nested && (nested_parent = nested[:parent]) && nested_parent.respond_to?(:object)
            @parent_form = nested_parent
            @nested_index = nested[:index]
            @attributes_name = "#{nested[:association]}_attributes"
          end
        end

        def error_messages(*params)
          @template.error_messages_for object, *params
        end

        def error_message_on(field, options={})
          @template.error_message_on object, field, options
        end

        def label(field, options={}, &block)
          @template.label_tag(field_id(field), { :caption => "#{field_human_name(field)}: " }.update(options), &block)
        end

        def hidden_field(field, options={})
          @template.hidden_field_tag field_name(field), default_options(field, options)
        end

        def text_field(field, options={})
          @template.text_field_tag field_name(field), default_options(field, options)
        end

        def number_field(field, options={})
          @template.number_field_tag field_name(field), default_options(field, options)
        end

        def telephone_field(field, options={})
          @template.telephone_field_tag field_name(field), default_options(field, options)
        end
        alias_method :phone_field, :telephone_field

        def email_field(field, options={})
          @template.email_field_tag field_name(field), default_options(field, options)
        end

        def search_field(field, options={})
          @template.search_field_tag field_name(field), default_options(field, options)
        end

        def url_field(field, options={})
          @template.url_field_tag field_name(field), default_options(field, options)
        end

        def text_area(field, options={})
          @template.text_area_tag field_name(field), default_options(field, options)
        end

        def password_field(field, options={})
          @template.password_field_tag field_name(field), default_options(field, options)
        end

        def select(field, options={})
          @template.select_tag field_name(field), default_options(field, options)
        end

        def check_box_group(field, options={})
          labeled_group(field, options) do |attributes|
            @template.check_box_tag(field_name(field)+'[]', attributes)
          end
        end

        def radio_button_group(field, options={})
          labeled_group(field, options) do |attributes|
            @template.radio_button_tag(field_name(field), attributes)
          end
        end

        def check_box(field, options={})
          options = default_options(field, options, :value => '1')
          options[:checked] = true if is_checked?(field, options)
          name = field_name(field)
          html = @template.hidden_field_tag(name, :value => options.delete(:uncheck_value) || '0')
          html << @template.check_box_tag(name, options)
        end

        def radio_button(field, options={})
          options = default_options(field, options)
          options[:checked] = true if is_checked?(field, options)
          options[:id] = field_id(field, options[:value])
          @template.radio_button_tag field_name(field), options
        end

        def file_field(field, options={})
          self.multipart = true
          @template.file_field_tag field_name(field), default_options(field, options).reject{ |key, _| key == :value }
        end

        def submit(*args)
          @template.submit_tag *args
        end

        def image_submit(source, options={})
          @template.image_submit_tag source, options
        end

        def datetime_field(field, options={})
          @template.datetime_field_tag field_name(field), default_options(field, options)
        end

        def datetime_local_field(field, options={})
          @template.datetime_local_field_tag field_name(field), default_options(field, options)
        end

        def date_field(field, options={})
          @template.date_field_tag field_name(field), default_options(field, options)
        end

        def month_field(field, options={})
          @template.month_field_tag field_name(field), default_options(field, options)
        end

        def week_field(field, options={})
          @template.week_field_tag field_name(field), default_options(field, options)
        end

        def time_field(field, options={})
          @template.time_field_tag field_name(field), default_options(field, options)
        end

        def color_field(field, options={})
          @template.color_field_tag field_name(field), default_options(field, options)
        end

        ##
        # Supports nested fields for a child model within a form.
        # f.fields_for :addresses
        # f.fields_for :addresses, address
        # f.fields_for :addresses, @addresses
        # f.fields_for :addresses, address, index: i
        def fields_for(child_association, collection=nil, options={}, &block)
          default_collection = self.object.send(child_association)
          collection ||= default_collection
          include_index = default_collection.respond_to?(:each)

          nested_options = { :parent => self, :association => child_association }
          Array(collection).each_with_index.inject(SafeBuffer.new) do |all,(child_instance,index)|
            nested_options[:index] = options[:index] || (include_index ? index : nil)
            all << @template.fields_for(child_instance,  { :nested => nested_options, :builder => self.class }, &block) << "\n"
          end
        end

        def csrf_token_field
          @template.csrf_token_field
        end

        protected

        # Returns the known field types for a Formbuilder.
        def self.field_types
          [:hidden_field, :text_field, :text_area, :password_field, :file_field, :radio_button, :check_box, :select,
            :number_field, :telephone_field, :email_field, :search_field, :url_field,
            :datetime_field, :datetime_local_field, :date_field, :month_field, :week_field, :time_field, :color_field,
          ]
        end

        ##
        # Returns the human name of the field. Look that use builtin I18n.
        #
        def field_human_name(field)
          I18n.translate("#{model_name}.attributes.#{field}", :count => 1, :default => Inflections.humanize(field), :scope => :models)
        end

        ##
        # Returns the object's models name.
        #
        def object_model_name(explicit_object=object)
          explicit_object.is_a?(Symbol) ? explicit_object : explicit_object.class.to_s.underscore.gsub(/\//, '_')
        end

        ##
        # Returns the name for the given field.
        # field_name(:username) => "user[username]"
        # field_name(:number) => "user[telephone_attributes][number]"
        # field_name(:street) => "user[addresses_attributes][0][street]"
        def field_name(field=nil)
          result = field_name_fragment
          result << "[#{field}]" if field
          result
        end

        ##
        # Returns the id for the given field.
        # field_id(:username) => "user_username"
        # field_id(:gender, :male) => "user_gender_male"
        # field_name(:number) => "user_telephone_attributes_number"
        # field_name(:street) => "user_addresses_attributes_0_street"
        def field_id(field=nil, value=nil)
          result = (namespace && !is_nested) ? "#{namespace}_" : ''
          result << field_id_fragment
          result << "_#{field}" if field
          result << "_#{value}" if value
          result
        end

        ##
        # Returns the child object if it exists.
        #
        def nested_object_id
          is_nested && object.respond_to?(:new_record?) && !object.new_record? && object.id
        end

        ##
        # Returns the value for the object's field.
        #
        def field_value(field)
          @object.respond_to?(field) ? @object.send(field) : ''
        end

        ##
        # Returns a record from template instance or create a record of specified class.
        #
        def build_object(symbol)
          @template.instance_variable_get("@#{symbol}") || Inflections.constantize(Inflections.camelize(symbol)).new
        end

        ##
        # Builds a group of labels for radios or checkboxes.
        #
        def labeled_group(field, options={})
          options = { :id => field_id(field), :selected => field_value(field) }.update(options)
          options.update(error_class(field)){ |_,*values| values.compact.join(' ') }
          selected_values = resolve_checked_values(field, options)
          variants_for_group(options).inject(SafeBuffer.new) do |html, (caption,value)|
            variant_id = "#{options[:id]}_#{value}"
            attributes = { :value => value, :id => variant_id, :checked => selected_values.include?(value) }
            caption = yield(attributes) << ' ' << caption
            html << @template.label_tag("#{field_name(field)}[]", :for => variant_id, :caption => caption)
          end
        end

        private

        def is_checked?(field, options)
          !options.has_key?(:checked) && [options[:value].to_s, 'true'].include?(field_value(field).to_s)
        end

        def variants_for_group(options)
          if variants = options[:options]
            variants.map{ |caption, value| [caption.to_s, (value||caption).to_s] }
          elsif collection = options[:collection]
            collection.map{ |variant| field_values(variant, options) }
          else
            []
          end
        end

        def resolve_checked_values(field, options)
          selected_values = Array(options[:selected] || field_value(field))
          if options[:collection]
            _, id_method = *field_methods(options)
            selected_values.map do |value|
              (value.respond_to?(id_method) ? value.send(id_method) : value).to_s
            end
          else
            selected_values
          end
        end

        def field_methods(options)
          options[:fields] || [:name, :id]
        end

        def field_values(object, options)
          field_methods(options).map{ |field| object.send(field).to_s }
        end

        def field_name_fragment
          if is_nested
            fragment = parent_form.field_name.dup << "[#{attributes_name}"
            fragment << "][#{nested_index}" if nested_index
            fragment << "]"
          else
            "#{model_name}"
          end
        end

        def field_id_fragment
          if is_nested
            fragment = parent_form.field_id.dup << "_#{attributes_name}"
            fragment << "_#{nested_index}" if nested_index
            fragment
          else
            "#{model_name}"
          end
        end

        def error_class(field)
          error = @object.errors[field] if @object.respond_to?(:errors)
          error.nil? || error.empty? ? {} : { :class => 'invalid' }
        end

        def default_options(field, options, defaults={})
          { :value => field_value(field),
            :id => field_id(field)
          }.update(defaults).update(options).update(error_class(field)){ |_,*values| values.compact.join(' ') }
        end
      end
    end
  end
end
