require 'padrino/core_ext/output_safety'
require 'padrino-support'
require 'pathname'

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
    # Defines common content-type alias mappings.
    #
    CONTENT_TYPE_ALIASES = { :htm => :html }

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
        if defined?(Padrino::Application) && app == Padrino::Application
          # this fail can be removed later when jRuby is not bugged and MRI19 is dropped
          fail 'Please, do not use `register` on Padrino::Application object, use `.dup` or subclassing'
        end
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
      # Returns the cached layout path.
      #
      # @param [String, nil] given_layout
      #   The requested layout.
      # @param [String, nil] layouts_path
      #   The directory where the layouts are located. Defaults to #views.
      #
      def fetch_layout_path(given_layout, layouts_path=views)
        layout_name = (given_layout || @layout || :application).to_s
        cache_layout_path(layout_name) do
          if Pathname.new(layout_name).absolute? && Dir["#{layout_name}.*"].any? || Dir["#{layouts_path}/#{layout_name}.*"].any?
            layout_name
          else
            File.join('layouts', layout_name)
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

        ensure_rendering_engine(engine) || (options[:layout] ||= @layout || false)

        # Cleanup the template.
        @current_engine, engine_was = engine, @current_engine
        @_out_buf,  buf_was = SafeBuffer.new, @_out_buf

        # Pass arguments to Sinatra render method.
        super(engine, data, with_layout(options), locals, &block)
      ensure
        @current_engine = engine_was
        @_out_buf = buf_was
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
        controller_key = respond_to?(:request) && request.respond_to?(:controller) && request.controller
        rendering_options = [template_path, content_type || :html, locale]

        settings.cache_template_path(["#{controller_key}/#{template_path}", rendering_options[1], rendering_options[2]]) do
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

      def resolve_layout(layout, options={})
        layouts_path = options[:layout_options] && options[:layout_options][:views] || options[:views] || settings.views || "./views"
        template_path = settings.fetch_layout_path(layout, layouts_path)
        rendering_options = [template_path, content_type || :html, locale]

        settings.cache_template_path(rendering_options) do
          template_candidates = glob_templates(layouts_path, template_path)
          selected_template = select_template(template_candidates, *rendering_options)

          fail TemplateNotFound, "Layout '#{template_path}' not found in '#{layouts_path}'" if !selected_template && layout
          selected_template
        end
      end

      def with_layout(options)
        options = options.dup
        layout = options[:layout]
        return options if layout == false

        layout = @layout if !layout || layout == true
        return options if settings.templates.has_key?(:layout) && !layout

        if layout.kind_of?(String) && Pathname.new(layout).absolute?
          layout_path, _, layout = layout.rpartition('/')
          options[:layout_options] ||= {}
          options[:layout_options][:views] ||= layout_path
        end
        layout, layout_engine = resolve_layout(layout, options)
        options.update(:layout => layout, :layout_engine => layout_engine)
      end

      def glob_templates(views_path, template_path)
        parts = []
        parts << views_path if views_path
        if respond_to?(:request) && request.respond_to?(:controller) && request.controller && Pathname.new(template_path).relative?
          parts << "{,#{request.controller}}"
        end
        parts << template_path.chomp(File.extname(template_path)) + '.*'
        Dir.glob(File.join(parts)).inject([]) do |all,file|
          next all if IGNORE_FILE_PATTERN.any?{ |pattern| file.to_s =~ pattern }
          all << path_and_engine(file, views_path)
        end
      end

      def select_template(templates, template_path, content_type, _locale)
        symbol = content_type_symbol(content_type)
        simple_content_type = [:html, :plain].include?(symbol)
        target_path, target_engine = path_and_engine(template_path)

        templates.find{ |file,_| file.to_s == "#{target_path}.#{locale}.#{symbol}" } ||
        templates.find{ |file,_| file.to_s == "#{target_path}.#{locale}" && simple_content_type } ||
        templates.find{ |file,engine| engine == target_engine || File.extname(file.to_s) == ".#{target_engine}" } ||
        templates.find{ |file,_| file.to_s == "#{target_path}.#{symbol}" } ||
        templates.find{ |file,_| file.to_s == "#{target_path}" && simple_content_type }
      end

      def path_and_engine(path, relative=nil)
        extname = File.extname(path)
        engine = (extname[1..-1]||'none').to_sym
        path = path.chomp(extname)
        path.insert(0, '/') unless Pathname.new(path).absolute?
        path = path.squeeze('/').sub(relative, '') if relative
        [path.to_sym, engine.to_sym]
      end

      def ensure_rendering_engine(engine)
        return true if settings.respond_to?(engine)
        return nil unless engine == :erb
        require 'erb'
      rescue LoadError
      else
        require 'padrino/rendering/erb_template'
        settings.set :erb, Padrino::Rendering.engine_configurations[:erb]
      end

      def content_type_symbol(type)
        if defined?(::Rack::Mime::MIME_TYPES) && type.kind_of?(String) &&
           ::Rack::Mime::MIME_TYPES.key(type)
          type = ::Rack::Mime::MIME_TYPES.key(type).sub(/\./,'').to_sym
        end
        CONTENT_TYPE_ALIASES[type] || type
      end
    end
  end
end

unless defined? Padrino::Rendering::HamlTemplate
  begin
    require 'haml'
    require 'haml/helpers/xss_mods'
    require 'haml/helpers/action_view_extensions'
  rescue LoadError
  else
    require 'padrino/rendering/haml_template'
  end
end

unless defined? Padrino::Rendering::ErubisTemplate
  begin
    require 'erubis'
  rescue LoadError
  else
    require 'padrino/rendering/erubis_template'
  end
end

unless defined? Padrino::Rendering::SlimTemplate
  begin
    require 'slim'
  rescue LoadError
  else
    require 'padrino/rendering/slim_template'
  end
end
