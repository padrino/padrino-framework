module Padrino
  module Helpers
    ##
    # Helpers related to rendering within templates (i.e partials).
    #
    module RenderHelpers
      ##
      # Render a partials with collections support.
      #
      # @param [String] template
      #   Relative path to partial template.
      # @param [Hash] options
      #   Options hash for rendering options.
      # @option options [Object] :object
      #   Object rendered in partial.
      # @option options [Array<Object>] :collection
      #   Partial is rendered for each object in this collection.
      # @option options [Hash] :locals ({})
      #   Local variables accessible in the partial.
      # @option options [Symbol] :engine
      #   Explicit rendering engine to use for this partial.
      #
      # @return [String] The html generated from this partial.
      #
      # @example
      #   partial 'photo/item', :object => @photo
      #   partial 'photo/item', :collection => @photos
      #   partial 'photo/item', :locals => { :foo => :bar }
      #   partial 'photo/item', :engine => :erb
      #
      # @note If using this from Sinatra, pass explicit +:engine+ option
      #
      def partial(template, options={}, &block)
        options = { :locals => {}, :layout => false }.update(options)
        explicit_engine = options.delete(:engine)

        path,_,name = template.to_s.rpartition(File::SEPARATOR)
        template_path = File.join(path,"_#{name}").to_sym
        item_name = name.partition('.').first.to_sym

        items, counter = if options[:collection].respond_to?(:inject)
          [options.delete(:collection), 0]
        else
          [[options.delete(:object)], nil]
        end

        locals = options[:locals]
        items.each_with_object(ActiveSupport::SafeBuffer.new) do |item,html|
          locals[item_name] = item if item
          locals["#{item_name}_counter".to_sym] = counter += 1 if counter
          content =
            if block_given?
              concat_content render(explicit_engine, template_path, options){ capture_html(&block) }
            else
              render(explicit_engine, template_path, options)
            end
          html.safe_concat content if content
        end
      end
      alias :render_partial :partial
    end
  end
end
