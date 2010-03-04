module Padrino
  module Helpers
    module RenderHelpers
      ##
      # Partials implementation which includes collections support
      # 
      # ==== Examples
      # 
      #   partial 'photo/item', :object => @photo
      #   partial 'photo/item', :collection => @photos
      #   partial 'photo/item', :locals => { :foo => :bar }
      # 
      def partial(template, options={})
        options.reverse_merge!(:locals => {}, :layout => false)
        path = template.to_s.split(File::SEPARATOR)
        object_name = path[-1].to_sym
        path[-1] = "_#{path[-1]}"
        template_path = File.join(path)
        raise 'Partial collection specified but is nil' if options.has_key?(:collection) && options[:collection].nil?
        if collection = options.delete(:collection)
          options.delete(:object)
          counter = 0
          collection.collect { |member|
            counter += 1
            options[:locals].merge!(object_name => member, "#{object_name}_counter".to_sym => counter)
            render(template_path, nil, options.dup)
          }.join("\n")
        else
          if member = options.delete(:object)
            options[:locals].merge!(object_name => member)
          end
          render(template_path, nil, options.dup)
        end
      end
      alias :render_partial :partial
    end # RenderHelpers
  end # Helpers
end # Padrino
