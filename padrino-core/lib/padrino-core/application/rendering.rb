module Padrino
  ##
  # Padrino enhances the Sinatra ‘render’ method to have support for automatic template engine detection,
  # enhanced layout functionality, locale enabled rendering, among other features.
  #
  module Rendering
    class TemplateNotFound < RuntimeError #:nodoc:
    end

    ##
    # This is an array of file patterns to ignore.
    # If your editor add a suffix during editing to your files please add it like:
    #
    #   Padrino::Rendering::IGNORE_FILE_PATTERN << /~$/
    #
    IGNORE_FILE_PATTERN = [
      /~$/ # This is for Gedit
    ]

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

      ##
      # Returns the cached template file to render for a given url, content_type and locale.  
      #
      # render_options = [template_path, content_type, locale]
      #
      def fetch_template_file(render_options)
        (@_cached_templates ||= {})[render_options]
      end
      
      ###
      # Caches the template file for the given rendering options 
      # 
      # render_options = [template_path, content_type, locale]
      # 
      def cache_template_file!(template_file, render_options)
        (@_cached_templates ||= {})[render_options] = template_file || []
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
          logger.debug "Resolving layout #{options[:layout]}" if defined?(logger) && options[:layout].present?
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
        has_layout_at_root = Dir["#{self.settings.views}/#{layout_var}.*"].any?
        layout_path = has_layout_at_root ? layout_var.to_sym : File.join('layouts', layout_var.to_s).to_sym
        located_template = resolve_template(layout_path, :strict_format => true)[0] rescue nil
      end

      ##
      # Returns the template path and engine that match content_type (if present), I18n.locale.
      #
      # === Options
      #
      #   :strict_format::  The resolved template must match the content_type of the request (defaults to false)
      #
      # ==== Example
      #
      #   get "/foo", :respond_to => [:html, :js] do; render 'path/to/foo'; end
      #   # If you request "/foo.js" with I18n.locale == :ru => [:"/path/to/foo.ru.js", :erb]
      #   # If you request "/foo" with I18n.locale == :de => [:"/path/to/foo.de.haml", :haml]
      #
      def resolve_template(template_path, options={})
        # Fetch cached template for rendering options
        template_path = "/#{template_path}" unless template_path.to_s =~ %r{^/}
        rendering_options = [template_path, content_type, locale]
        cached_template = self.class.fetch_template_file(rendering_options)
        return cached_template if cached_template

        # Resolve view path and options
        options.reverse_merge!(:strict_format => false)
        view_path = options.delete(:views) || self.options.views || self.class.views || "./views"
        target_extension = File.extname(template_path)[1..-1] || "none" # retrieves explicit template extension
        template_path = template_path.chomp(".#{target_extension}")

        # Generate potential template candidates
        templates = Dir[File.join(view_path, template_path) + ".*"].map do |file|
          template_engine = File.extname(file)[1..-1].to_sym # retrieves engine extension
          template_file   =  file.sub(view_path, '').chomp(".#{template_engine}").to_sym # retrieves template filename
          [template_file, template_engine] unless IGNORE_FILE_PATTERN.any? { |pattern| template_engine.to_s =~ pattern }
        end

        # Resolve final template to render
        located_template =
          templates.find { |file, e| file.to_s == "#{template_path}.#{locale}.#{content_type}" } ||
          templates.find { |file, e| file.to_s == "#{template_path}.#{locale}" && content_type == :html } ||
          templates.find { |file, e| File.extname(file.to_s) == ".#{target_extension}" or e.to_s == target_extension.to_s } ||
          templates.find { |file, e| file.to_s == "#{template_path}.#{content_type}" } ||
          templates.find { |file, e| file.to_s == "#{template_path}" && content_type == :html } ||
          templates.any? && !options[:strict_format] && templates.first # If not strict, fall back to the first located template

        self.class.cache_template_file!(located_template, rendering_options) unless settings.reload_templates?
        raise TemplateNotFound.new("Template path '#{template_path}' could not be located!")  unless located_template
        located_template
      end

      ##
      # Return the I18n.locale if I18n is defined
      #
      def locale
        I18n.locale if defined?(I18n)
      end
  end # Rendering
end # Padrino