module Padrino
  module Rendering
    private
      ##
      # Hijacking the sinatra render for do three thing:
      #
      # * Use layout like rails do
      # * Use render 'path/to/my/template' (without symbols)
      # * Use render 'path/to/my/template' (with auto enegine lookup)
      #
      def render(engine, data=nil, options={}, locals={}, &block)
        # TODO: remove these @template_cache.respond_to?(:clear) when sinatra 1.0 will be released
        @template_cache.clear if Padrino.env != :production && @template_cache && @template_cache.respond_to?(:clear)
        # If engine is an hash we convert to json
        return engine.to_json if engine.is_a?(Hash)
        # If an engine is a string probably is a path so we try to resolve them
        if data.nil?
          data   = engine.to_sym
          engine = resolve_template_engine(engine)
        end
        # Use layout as rails do
        if (options[:layout].nil? || options[:layout] == true) && !self.class.templates.has_key?(:layout)
          layout = self.class.instance_variable_defined?(:@_layout) ? self.class.instance_variable_get(:@_layout) : :application
          if layout
            # We look first for views/layout_name.ext then then for views/layouts/layout_name.ext
            options[:layout] = Dir["#{self.options.views}/#{layout}.*"].present? ? layout.to_sym : File.join('layouts', layout.to_s).to_sym
            logger.debug "Rendering layout #{options[:layout]}"
          end
        end
        super(engine, data, options, locals, &block)
      end

      ##
      # Returns the template engine (i.e haml) to use for a given template_path
      # resolve_template_engine('users/new') => :haml
      #
      def resolve_template_engine(template_path)
        resolved_template_path = File.join(self.options.views, template_path.to_s + ".*")
        template_file = Dir[resolved_template_path].first
        raise "Template path '#{template_path}' could not be located in views!" unless template_file
        template_engine = File.extname(template_file)[1..-1].to_sym
      end
  end
end
