module Padrino
  module Helpers
    module FormBuilder
      module DeprecatedBuilderMethods
        ##
        # Returns true if the value matches the value in the field.
        # field_has_value?(:gender, 'male')
        def values_matches_field?(field, value)
          logger.warn "##{__method__} is deprecated"
          value.present? && (field_value(field).to_s == value.to_s || field_value(field).to_s == 'true')
        end

        ##
        # Add a :invalid css class to the field if it contain an error.
        #
        def field_error(field, options)
          logger.warn "##{__method__} is deprecated"
          error = @object.errors[field] rescue nil
          error.blank? ? options[:class] : [options[:class], :invalid].flatten.compact.join(" ")
        end

        def nested_form?
          logger.warn "##{__method__} is deprecated"
          @options[:nested] && @options[:nested][:parent] && @options[:nested][:parent].respond_to?(:object)
          is_nested && object.respond_to?(:new_record?) && !object.new_record? && object.id
        end

        ##
        # Returns the object's models name.
        #
        def object_model_name(explicit_object=object)
          logger.warn "##{__method__} is deprecated"
          return @options[:as] if root_form? && @options[:as].is_a?(Symbol)
          explicit_object.is_a?(Symbol) ? explicit_object : explicit_object.class.to_s.underscore.gsub(/\//, '_')
        end

        ##
        # Returns the class type for the given object.
        #
        def object_class(explicit_object)
          logger.warn "##{__method__} is deprecated"
          explicit_object.is_a?(Symbol) ? explicit_object.to_s.camelize.constantize : explicit_object.class
          @object.respond_to?(field) ? @object.send(field) : ''
        end

        ##
        # Returns true if this form is the top-level (not nested).
        # Returns a record from template instance or create a record of specified class.
        #
        def root_form?
          logger.warn "##{__method__} is deprecated"
          !nested_form?
        end

        def field_result
          logger.warn "##{__method__} is deprecated"
          result = []
          result << object_model_name if root_form?
          result
        end

        def merge_default_options!(field, options)
          logger.warn "##{__method__} is deprecated"
          options.reverse_merge!(:value => field_value(field), :id => field_id(field))
          options.merge!(:class => field_error(field, options))
        end

        def result_options
          logger.warn "##{__method__} is deprecated"
          {
            :parent_form  => @options[:nested][:parent],
            :nested_index => @options[:nested][:index],
            :attributes_name => "#{@options[:nested][:association]}_attributes"
          }
        end
      end
    end
  end
end
