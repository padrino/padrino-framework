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
      # Enhancing Sinatra render functionality for:
      #
      # * Using layout similar to rails
      # * Use render 'path/to/my/template'   (without symbols)
      # * Use render 'path/to/my/template'   (with engine lookup)
      # * Use render 'path/to/template.haml' (with explicit engine lookup)
      # * Use render 'path/to/template', :layout => false
      # * Use render 'path/to/template', :layout => false, :engine => 'haml'
      # * Use render { :a => 1, :b => 2, :c => 3 } # => return a json string
      #
      def render(engine, data=nil, options={}, locals={}, &block)
        # Clear template view cache in development mode
        clear_template_cache!

        # If engine is a hash then render data converted to json
        return engine.to_json if engine.is_a?(Hash)

        # Data can actually be a hash of options in certain cases
        options.merge!(data) && data = nil if data.is_a?(Hash)

        # If an engine is a string then this is a likely a path to be resolved
        data, engine = *resolve_template(engine, options) if data.nil?

        # Sinatra 1.0 requires an outvar for erb and erubis templates
        options[:outvar] ||= '@_out_buf' if [:erb, :erubis].include?(engine)

        # Resolve layouts similar to in Rails
        if (options[:layout].nil? || options[:layout] == true) && !self.class.templates.has_key?(:layout)
          options[:layout] = resolved_layout
          logger.debug "Resolving layout #{options[:layout]}" if defined?(logger) && options[:layout]
        end

        # Pass arguments to Sinatra render method
        super(engine, data, options, locals, &block)
      end

      ##
      # Returns the located layout to be used for the rendered template (if available)
      #
      # ==== Example
      #
      # resolve_layout(true)
      # => "/layouts/custom"
      #
      def resolved_layout
        layout_var = self.class.instance_variable_get(:@_layout) || :application
        has_layout_at_root = Dir["#{self.options.views}/#{layout_var}.*"].any?
        layout_path = has_layout_at_root ? layout_var.to_sym : File.join('layouts', layout_var.to_s).to_sym
        resolve_template(layout_path)[0] rescue nil
      end

      ##
      # Returns the template path and engine that match content_type (if present), I18n.locale.
      #
      # ==== Example
      #
      #   get "/foo", :respond_to => [:html, :js] do; render 'path/to/foo'; end
      #   # If you request "/foo.js" with I18n.locale == :ru => [:"/path/to/foo.ru.js", :erb]
      #   # If you request "/foo" with I18n.locale == :de => [:"/path/to/foo.de.haml", :haml]
      #
      def resolve_template(template_path, options={})
        view_path = options.delete(:views) || self.options.views || self.class.views || "./views"
        template_path = "/#{template_path}" unless template_path.to_s =~ /^\//
        target_extension = File.extname(template_path)[1..-1] || "none" # retrieves explicit template extension
        template_path = template_path.chomp(".#{target_extension}")

        templates = Dir[File.join(view_path, template_path) + ".*"].map do |file|
          template_engine = options[:engine] || File.extname(file)[1..-1].to_sym       # retrieves engine extension
          template_file =  file.sub(view_path, '').chomp(".#{template_engine}").to_sym # retrieves template filename
          [template_file, template_engine]
        end

        located_template =
          templates.find { |file, e| defined?(I18n) && file.to_s == "#{template_path}.#{I18n.locale}.#{content_type}" } ||
          templates.find { |file, e| defined?(I18n) && file.to_s == "#{template_path}.#{I18n.locale}" && content_type == :html } ||
          templates.find { |file, e| File.extname(file.to_s) == ".#{target_extension}" or e.to_s == target_extension.to_s } ||
          templates.find { |file, e| file.to_s == "#{template_path}.#{content_type}" } ||
          templates.find { |file, e| file.to_s == "#{template_path}" && content_type == :html }

        raise "Template path '#{template_path}' could not be located and rendered!" unless located_template
        located_template
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
