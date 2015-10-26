module Padrino
  module Helpers
    module FormHelpers
      ##
      # Helpers to generate options list for select tag.
      #
      module Options
        def extract_option_tags!(options)
          state = extract_option_state!(options)
          option_tags = if options[:grouped_options]
            grouped_options_for_select(options.delete(:grouped_options), state)
          else
            options_for_select(extract_option_items!(options), state)
          end
          if prompt = options.delete(:include_blank)
            option_tags.unshift(blank_option(prompt))
          end
          option_tags
        end

        private

        ##
        # Returns the blank option serving as a prompt if passed.
        #
        def blank_option(prompt)
          case prompt
          when nil, false
            nil
          when String
            content_tag(:option, prompt,       :value => '')
          when Array
            content_tag(:option, prompt.first, :value => prompt.last)
          else
            content_tag(:option, '',           :value => '')
          end
        end

        ##
        # Returns whether the option should be selected or not.
        #
        # @example
        #   option_is_selected?("red", "Red", ["red", "blue"])   => true
        #   option_is_selected?("red", "Red", ["green", "blue"]) => false
        #
        def option_is_selected?(value, caption, selected_values)
          Array(selected_values).any? do |selected|
            value ?
              value.to_s == selected.to_s :
              caption.to_s == selected.to_s
          end
        end

        ##
        # Returns the options tags for a select based on the given option items.
        #
        def options_for_select(option_items, state = {})
          return [] if option_items.count == 0
          option_items.map do |caption, value, attributes|
            html_attributes = { :value => value || caption }.merge(attributes||{})
            html_attributes[:selected] ||= option_is_selected?(html_attributes[:value], caption, state[:selected])
            html_attributes[:disabled] ||= option_is_selected?(html_attributes[:value], caption, state[:disabled])
            content_tag(:option, caption, html_attributes)
          end
        end

        ##
        # Returns the optgroups with options tags for a select based on the given :grouped_options items.
        #
        def grouped_options_for_select(collection, state = {})
          collection.map do |item|
            caption = item.shift
            attributes = item.last.kind_of?(Hash) ? item.pop : {}
            value = item.flatten(1)
            attributes = value.pop if value.last.kind_of?(Hash)
            html_attributes = { :label => caption }.merge(attributes||{})
            content_tag(:optgroup, options_for_select(value, state), html_attributes)
          end
        end

        def extract_option_state!(options)
          {
            :selected => Array(options.delete(:value))|Array(options.delete(:selected))|Array(options.delete(:selected_options)),
            :disabled => Array(options.delete(:disabled_options))
          }
        end

        def extract_option_items!(options)
          if options[:collection]
            fields = options.delete(:fields)
            collection = options.delete(:collection)
            collection.map{ |item| [ item.send(fields.first), item.send(fields.last) ] }
          else
            options.delete(:options) || []
          end
        end
      end
    end
  end
end
