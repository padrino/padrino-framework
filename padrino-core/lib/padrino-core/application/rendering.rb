module Padrino
  module Rendering
    def self.registered(app)
      app.send(:include, Padrino::Rendering)
    end

    private
      ##
      # Hijacking the sinatra render for do three thing:
      #
      # * Use layout like rails do
      # * Use render 'path/to/my/template' (without symbols)
      # * Use render 'path/to/my/template' (with auto enegine lookup)
      #
      def render(engine, data=nil, options={}, locals={}, &block)
        clear_template_cache!

        # If engine is an hash we convert to json
        return engine.to_json if engine.is_a?(Hash)

        # If an engine is a string probably is a path so we try to resolve them
        data, engine = *resolve_template(engine, options) if data.nil?

        # We need for Sinatra 1.0 an outvar for erb and erubis templates
        options[:outvar] ||= '@_out_buf' if [:erb, :erubis].include?(engine)

        # Use layout as rails do
        if (options[:layout].nil? || options[:layout] == true) && !self.class.templates.has_key?(:layout)
          layout = self.class.instance_variable_defined?(:@_layout) ? self.class.instance_variable_get(:@_layout) : :application
          if layout
            # We look first for views/layout_name.ext then then for views/layouts/layout_name.ext
            options[:layout] = Dir["#{self.options.views}/#{layout}.*"].present? ? layout.to_sym : File.join('layouts', layout.to_s).to_sym
            logger.debug "Rendering layout #{options[:layout]}" if defined?(logger)
          end
        end
        super(engine, data, options, locals, &block)
      end

      ##
      # Returns the template path and engine that match (if presents) content_type, I18n.locale.
      # 
      # ==== Example
      # 
      #   get "/foo", :respond_to => [:html, :js] do; render 'path/to/foo'; end
      #   # If you request "/foo.js" with I18n.locale == :ru => [:"/path/to/foo.ru.js", :erb]
      #   # If you request "/foo" with I18n.locale == :de => [:"/path/to/foo.de.haml", :haml]
      # 
      def resolve_template(template_path, options={})
        view_path = options.delete(:views) || self.options.views || self.class.views || "./views"
        template_path   = File.join(view_path, template_path.to_s)
        regexs = [/^[^\.]+\.[^\.]+$/]
        regexs.unshift(/^[^\.]+\.#{content_type}\.[^\.]+$/) if content_type.present?
        if defined?(I18n) && I18n.locale.present?
          regexs.unshift(/^[^\.]+\.#{I18n.locale}\.[^\.]+$/)
          regexs.unshift(/^[^\.]+\.#{I18n.locale}\.#{content_type}\.[^\.]+$/) if content_type.present?
        end
        template_file = regexs.map { |regex| Dir[template_path + ".*"].find { |file| File.basename(file) =~ regex } }.compact.first
        raise "Template path '#{template_path}' could not be located in views!" unless template_file
        engine   = File.extname(template_file)[1..-1]
        template = template_file.gsub(view_path, '').gsub(/\.#{engine}$/, '')
        [template.to_sym, engine.to_sym]
      end

      ##
      # Clears the template view cache when in development mode
      # clear_template_cache!
      #
      def clear_template_cache!
        # TODO: remove @template_cache.respond_to?(:clear) when sinatra 1.0 will be released
        can_clear_cache = @template_cache && @template_cache.respond_to?(:clear)
        is_in_development = (defined?(Padrino) && Padrino.respond_to?(:env) && Padrino.env != :production)
        @template_cache.clear if is_in_development && can_clear_cache
      end
  end
end