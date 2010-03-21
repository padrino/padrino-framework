module Padrino
  ##
  # Padrino enhances the Sinatra ‘render’ method to have support for automatic template engine detection,
  # among other more advanced features.
  #
  module Rendering
    def self.registered(app)
      app.send(:include, Padrino::Rendering)
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      ##
      # Use layout like rails does or if a block given then like sinatra.
      # If used without a block, sets the current layout for the route.
      #
      # By default, searches in your +app+/+views+/+layouts+/+application+.(+haml+|+erb+|+xxx+)
      #
      # If you define +layout+ :+custom+ then searches for your layouts in
      # +app+/+views+/+layouts+/+custom+.(+haml+|+erb+|+xxx+)
      #
      def layout(name=:layout, &block)
        return super(name, &block) if block_given?
        @_layout = name
      end
    end

    private
      ##
      # Hijacking the sinatra render for:
      #
      # * Use layout like rails do
      # * Use render 'path/to/my/template' (without symbols)
      # * Use render 'path/to/my/template' (with auto enegine lookup)
      # * Use render 'path/to/template', :layout => false
      # * Use render { :a => 1, :b => 2, :c => 3 } # => return a json string
      #
      def render(engine, data=nil, options={}, locals={}, &block)
        clear_template_cache!

        # If engine is an hash we convert to json
        return engine.to_json if engine.is_a?(Hash)

        # Data can be a hash of options sometimes mistakenly
        options.merge!(data) && data = nil if data.is_a?(Hash)

        # If an engine is a string probably is a path so we try to resolve them
        data, engine = *resolve_template(engine, options) if data.nil?

        # We need for Sinatra 1.0 an outvar for erb and erubis templates
        options[:outvar] ||= '@_out_buf' if [:erb, :erubis].include?(engine)

        # Use layout as rails do
        if (options[:layout].nil? || options[:layout] == true) && !self.class.templates.has_key?(:layout)
          if layout = self.class.instance_variable_defined?(:@_layout) ? self.class.instance_variable_get(:@_layout) : :application
            layout = Dir["#{self.options.views}/#{layout}.*"].any? ? layout.to_sym : File.join('layouts', layout.to_s).to_sym
            options[:layout] = resolve_template(layout)[0] rescue nil
            logger.debug "Rendering layout #{options[:layout]}" if defined?(logger) && options[:layout]
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
        template_path = "/#{template_path}" unless template_path.to_s =~ /^\//
        view_path = options.delete(:views) || self.options.views || self.class.views || "./views"
        templates = Dir[File.join(view_path, template_path) + ".*"].
                      map { |f| [f.sub(view_path, '').chomp(File.extname(f)).to_sym, File.extname(f)[1..-1].to_sym] }

        template =
          templates.find { |t| defined?(I18n) && t[0].to_s == "#{template_path}.#{I18n.locale}.#{content_type}" } ||
          templates.find { |t| defined?(I18n) && t[0].to_s == "#{template_path}.#{I18n.locale}" && content_type == :html } ||
          templates.find { |t| t[0].to_s == "#{template_path}.#{content_type}" } ||
          templates.find { |t| t[0].to_s == "#{template_path}" && content_type == :html }

        raise "Template path '#{template_path}' could not be located in views!" unless template
        template
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
  end # Rendering
end # Padrino