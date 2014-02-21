require 'padrino-core/support_lite' unless defined?(SupportLite)

module Padrino
  ##
  # Padrino enhances the Sinatra 'render' method to have support for
  # automatic template engine detection, enhanced layout functionality,
  # locale enabled rendering, among other features.
  #
  module Rendering
    ##
    # A SafeTemplate assumes that its output is safe.
    #
    module SafeTemplate
      def render(*)
        super.html_safe
      end
    end

    ##
    # Exception responsible for when an expected template did not exist.
    #
    class TemplateNotFound < RuntimeError
    end

    ##
    # This is an array of file patterns to ignore. If your editor add a
    # suffix during editing to your files please add it like:
    #
    # @example
    #   Padrino::Rendering::IGNORE_FILE_PATTERN << /~$/
    #
    IGNORE_FILE_PATTERN = [
      /~$/ # This is for Gedit
    ] unless defined?(IGNORE_FILE_PATTERN)

    ##
    # Default options used in the resolve_template-method.
    #
    DEFAULT_RENDERING_OPTIONS = { :strict_format => false, :raise_exceptions => true } unless defined?(DEFAULT_RENDERING_OPTIONS)

    class << self
      ##
      # Default engine configurations for Padrino::Rendering.
      #
      # @return {Hash<Symbol,Hash>}
      #   The configurations, keyed by engine.
      def engine_configurations
        @engine_configurations ||= {}
      end

      def registered(app)
        included(app)
        engine_configurations.each do |engine, configs|
          app.set engine, configs
        end
      end

      def included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
      end
    end

    ##
    # Class methods responsible for rendering templates as part of a request.
    #
    module ClassMethods
      ##
      # Use layout like rails does or if a block given then like sinatra.
      # If used without a block, sets the current layout for the route.
      #
      # By default, searches in your:
      #
      # +app+/+views+/+layouts+/+application+.(+haml+|+erb+|+xxx+)
      # +app+/+views+/+layout_name+.(+haml+|+erb+|+xxx+)
      #
      # If you define +layout+ :+custom+ then searches for your layouts in
      # +app+/+views+/+layouts+/+custom+.(+haml+|+erb+|+xxx+)
      # +app+/+views+/+custom+.(+haml+|+erb+|+xxx+)
      #
      # @param [Symbol] name (:layout)
      #   The layout to use.
      #
      # @yield []
      #
      def layout(name=:layout, &block)
        return super(name, &block) if block_given?
        @layout = name
      end

      ##
      # Returns the cached template file to render for a given url,
      # content_type and locale.
      #
      # @param [Array<template_path, content_type, locale>] render_options
      #
      def fetch_template_file(render_options)
        logger.warn "##{__method__} is deprecated"
        (@_cached_templates ||= {})[render_options]
      end

      ##
      # Caches the template file for the given rendering options.
      #
      # @param [String] template_file
      #   The path of the template file.
      #
      # @param [Array<template_path, content_type, locale>] render_options
      #
      def cache_template_file!(template_file, render_options)
        logger.warn "##{__method__} is deprecated"
        (@_cached_templates ||= {})[render_options] = template_file || []
      end

      ##
      # Returns the cached layout path.
      #
      # @param [Symbol, nil] given_layout
      #   The requested layout.
      #
      def fetch_layout_path(given_layout=nil)
        layout_name = given_layout || @layout || :application
        cache_layout_path(layout_name) do
          if Dir["#{views}/#{layout_name}.*"].any?
            layout_name.to_sym
          else
            File.join('layouts', layout_name.to_s).to_sym
          end
        end
      end

      def cache_layout_path(name)
        @_cached_layout ||= {}
        if !reload_templates? && path = @_cached_layout[name]
          path
        else
          @_cached_layout[name] = yield(name)
        end
      end

      def cache_template_path(options)
        began_at = Time.now
        @_cached_templates ||= {}
        logging = defined?(settings) && settings.logging? && defined?(logger)
        if !reload_templates? && path = @_cached_templates[options]
          logger.debug :cached, began_at, path[0] if logging
        else
          path = @_cached_templates[options] = yield(name)
          logger.debug :template, began_at, path[0] if path && logging
        end
        path
      end
    end

    # Instance methods that allow enhanced rendering to function properly in Padrino.
    module InstanceMethods
      attr_reader :current_engine

      ##
      # Get/Set the content_type
      #
      # @param [String, nil] type
      #   The Content-Type to use.
      #
      # @param [Symbol, nil] type.
      #   Look and parse the given symbol to the matched Content-Type.
      #
      # @param [Hash] params
      #   Additional params to append to the Content-Type.
      #
      # @example
      #   case content_type
      #     when :js then do_some
      #     when :css then do_another
      #   end
      #
      #   content_type :js
      #   # => set the response with 'application/javascript' Content-Type
      #   content_type 'text/html'
      #
      #   # => set directly the Content-Type to 'text/html'
      #
      def content_type(type=nil, params={})
        if type
          super(type, params)
          @_content_type = type
        end
        @_content_type
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
      #
      def render(engine, data=nil, options={}, locals={}, &block)
        # If engine is nil, ignore engine parameter and shift up all arguments
        # render nil, "index", { :layout => true }, { :localvar => "foo" }
        engine, data, options = data, options, locals if engine.nil? && data

        # Data is a hash of options when no engine isn't explicit
        # render "index", { :layout => true }, { :localvar => "foo" }
        # Data is options, and options is locals in this case
        data, options, locals = nil, data, options if data.is_a?(Hash)

        # If data is unassigned then this is a likely a template to be resolved
        # This means that no engine was explicitly defined
        data, engine = resolve_template(engine, options) if data.nil?

        # Cleanup the template.
        @current_engine, engine_was = engine, @current_engine
        @_out_buf,  buf_was = ActiveSupport::SafeBuffer.new, @_out_buf

        options = with_layout(options)

        # Pass arguments to Sinatra render method.
        super(engine, data, options.dup, locals, &block)
      ensure
        @current_engine = engine_was
        @_out_buf = buf_was
      end

      ##
      # Returns the located layout tuple to be used for the rendered template
      # (if available).
      #
      # @example
      #   resolve_layout
      #   # => ["/layouts/custom", :erb]
      #   # => [nil, nil]
      #
      def resolved_layout
        resolve_template(settings.fetch_layout_path, :raise_exceptions => false, :strict_format => true) || [nil, nil]
      end

      ##
      # Returns the template path and engine that match content_type (if present),
      # I18n.locale.
      #
      # @param [String] template_path
      #   The path of the template.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @option options [Boolean] :strict_format (false)
      #   The resolved template must match the content_type of the request.
      #
      # @option options [Boolean] :raise_exceptions (false)
      #   Raises a {TemplateNotFound} exception if the template cannot be located.
      #
      # @return [Array<Symbol, Symbol>]
      #   The path and format of the template.
      #
      # @raise [TemplateNotFound]
      #   The template could not be found.
      #
      # @example
      #   get "/foo", :provides => [:html, :js] do; render 'path/to/foo'; end
      #   # If you request "/foo.js" with I18n.locale == :ru => [:"/path/to/foo.ru.js", :erb]
      #   # If you request "/foo" with I18n.locale == :de => [:"/path/to/foo.de.haml", :haml]
      #
      def resolve_template(template_path, options={})
        template_path = template_path.to_s
        template_path.insert(0, '/') unless template_path.start_with?('/')
        rendering_options = [template_path, content_type || :html, locale]

        settings.cache_template_path(rendering_options) do
          options = DEFAULT_RENDERING_OPTIONS.merge(options)
          view_path = options[:views] || settings.views || "./views"

          template_candidates = glob_templates(view_path, template_path)
          selected_template = select_template(template_candidates, *rendering_options)
          selected_template ||= template_candidates.first unless options[:strict_format]

          fail TemplateNotFound, "Template '#{template_path}' not found in '#{view_path}'"  if !selected_template && options[:raise_exceptions]
          selected_template
        end
      end

      ##
      # Return the I18n.locale if I18n is defined.
      #
      def locale
        I18n.locale if defined?(I18n)
      end

      LAYOUT_EXTENSIONS = %w[.slim .erb .haml].freeze

      def with_layout(options)
        layout = options[:layout]
        return options if layout == false

        layout = @layout if !layout || layout == true
        layout_path = settings.fetch_layout_path(layout)
        if layout.present?
          layout, layout_engine = resolve_template(layout_path, options)
        elsif !settings.templates.has_key?(:layout)
          is_included_extension = LAYOUT_EXTENSIONS.include?(File.extname(layout_path.to_s))
          layout_path, layout_engine = resolved_layout
          layout = layout_path || false
          layout = false unless is_included_extension ? layout_engine : layout_engine == @current_engine
        else
          return options
        end

        options.merge(:layout_engine => layout_engine, :layout => layout)
      end

      def glob_templates(views_path, template_path)
        parts = [views_path]
        parts << "{,#{request.controller}}" if respond_to?(:request) && request.controller.present?
        parts << template_path.chomp(File.extname(template_path)) + '.*'
        Dir.glob(File.join(parts)).inject([]) do |all,file|
          next all if IGNORE_FILE_PATTERN.any?{ |pattern| file.to_s =~ pattern }
          extname = File.extname(file)
          all << [file.squeeze('/').sub(views_path, '').chomp(extname).to_sym, extname[1..-1].to_s.to_sym]
        end
      end

      def select_template(templates, template_path, content_type, _locale)
        simple_content_type = [:html, :plain].include?(content_type)

        templates.find{ |file,_| file.to_s == "#{template_path}.#{locale}.#{content_type}" } ||
        templates.find{ |file,_| file.to_s == "#{template_path}.#{locale}" && simple_content_type } ||
        templates.find do |file,engine|
          target_engine = File.extname(template_path)[1..-1].to_s.to_sym
          File.extname(file.to_s) == ".#{target_engine}" || engine == target_engine
        end ||
        templates.find{ |file,_| file.to_s == "#{template_path}.#{content_type}" } ||
        templates.find{ |file,_| file.to_s == "#{template_path}" && simple_content_type }
      end
    end
  end
end

require 'padrino-core/application/rendering/extensions/haml'
require 'padrino-core/application/rendering/extensions/erubis'
require 'padrino-core/application/rendering/extensions/slim'
