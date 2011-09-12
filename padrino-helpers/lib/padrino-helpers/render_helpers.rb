module Padrino
  module Helpers
    module RenderHelpers
      ##
      # Tell the client that the response includes an inline file attachment.
      #
      # @note Inline attachment means the client wont directly download the
      #   file, just show it inside the browser
      # @note Sinatra::Base#send_file already supports inline attachment.
      #   However, it's not always the case the developer wants to read from
      #   a source path
      #
      # @param [optional String] filename
      #   Filename to represent
      #
      # @example
      #   inline_attachment "my_script.sh"
      #   send_file "/path/to/my_script.sh"
      #
      # @see Sinatra::Base#attachment
      #
      # @api public
      def inline_attachment(filename = nil)
        value = "Inline"

        if filename
          value << "; filename=\"#{File.basename filename}\""
        end

        response["Content-Disposition"] = value
      end

      ##
      # Render a partials with collections support
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
      #   Explicit rendering engine to use for this partial
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
      # @api public
      def partial(template, options={})
        logger.debug "PARTIAL:  #{template} called" if defined?(logger)
        options.reverse_merge!(:locals => {}, :layout => false)
        path = template.to_s.split(File::SEPARATOR)
        object_name = path[-1].to_sym
        path[-1] = "_#{path[-1]}"
        explicit_engine = options.delete(:engine)
        template_path = File.join(path).to_sym
        raise 'Partial collection specified but is nil' if options.has_key?(:collection) && options[:collection].nil?
        if collection = options.delete(:collection)
          options.delete(:object)
          counter = 0
          collection.map { |member|
            counter += 1
            options[:locals].merge!(object_name => member, "#{object_name}_counter".to_sym => counter)
            render(explicit_engine, template_path, options.dup)
          }.join("\n")
        else
          if member = options.delete(:object)
            options[:locals].merge!(object_name => member)
          end
          render(explicit_engine, template_path, options.dup)
        end
      end
      alias :render_partial :partial
    end # RenderHelpers
  end # Helpers
end # Padrino
