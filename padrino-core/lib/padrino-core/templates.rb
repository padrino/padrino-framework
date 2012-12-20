require 'padrino-core/settings'

module Padrino
  # as well as an optional hash with additional options.
  #
  # `template` is either the name or path of the template as symbol
  # (Use `:'subdir/myview'` for views in subdirectories), or a string
  # that will be rendered.
  #
  # Possible options are:
  #   :content_type   The content type to use, same arguments as content_type.
  #   :layout         If set to false, no layout is rendered, otherwise
  #                   the specified layout is used (Ignored for `sass` and `less`)
  #   :layout_engine  Engine to use for rendering the layout.
  #   :locals         A hash with local variables that should be available
  #                   in the template
  #   :scope          If set, template is evaluate with the binding of the given
  #                   object rather than the application instance.
  #   :views          Views directory to use.
  module Templates

    def self.included(base)
      unless base.respond_to?(:render)
        base.extend(ClassMethods)
        base.init_templates!
      end
      super
    end

    module ContentTyped
      attr_accessor :content_type
    end

    ENGINES = {
      builder:  { content_type: :xml },
      coffee:   { content_type: :js, layout: false },
      creole:   {},
      erb:      {},
      haml:     {},
      less:     { content_type: :css, layout: false },
      liquid:   {},
      markaby:  {},
      markdown: {},
      nokogiri: { content_type: :xml },
      radius:   {},
      rdoc:     {},
      sass:     { content_type: :css, layout: false },
      scss:     { content_type: :css, layout: false },
      slim:     {},
      textile:  {}
    }

    def render(*args, &block)
      settings.render(*args, &block)
    end

    ENGINES.each do |engine, default|
      define_method(engine){ |*args, &block| settings.send(engine, *args, &block) }
    end

    module ClassMethods

      def init_templates!
        return if self == Application
        view_path = File.join(File.dirname(Padrino.first_caller), '/views')
        send :include, Settings               unless respond_to?(:settings)
        set :views, view_path                 unless respond_to?(:views)
        set :default_encoding, 'utf-8'        unless respond_to?(:default_encoding)
        set :templates, {}                    unless respond_to?(:templates)
        set :template_cache, Tilt::Cache.new  unless respond_to?(:template_cache)
        set :default_layout, :layout          unless respond_to?(:default_layout)
        set :default_engine, nil              unless respond_to?(:default_engine)
      end

      def inherited(base)
        base.init_templates! if self == Application
        super
      end

      def included(base)
        unless base.respond_to?(:render)
          base.extend(ClassMethods)
          base.send(:include, Settings) unless base.respond_to?(:settings)
          base.set :views,            views
          base.set :templates,        templates
          base.set :default_encoding, default_encoding
          base.set :template_cache,   template_cache
          base.set :default_layout,   default_layout
          base.set :default_engine,   default_engine
        end
        super
      end

      ENGINES.each do |engine, default|
        define_method(engine) do |data, options=default, locals={}, &block|
          render(data, options.merge(as: engine), locals, &block)
        end
      end

      # Define a named template. The block must return the template source.
      def template(name, &block)
        filename, line = Padrino.caller_locations.first
        settings.templates[name] = [block, filename, line.to_i]
      end

      # Define the layout template. The block must return the template source.
      def layout(name=:layout, &block)
        settings.template name, &block
      end

      # logic shared between builder and nokogiri
      def render_ruby(engine, template, options={}, locals={}, &block)
        options, template = template, nil if template.is_a?(Hash)
        template = Proc.new { block } if template.nil?
        render engine, template, options, locals
      end

      def find_template(views, name, preferred_ext=nil, &block)

        base_path = File.join(views, name.to_s)

        return base_path if File.exist?(base_path)

        if preferred_ext
          result = "#{base_path}.#{preferred_ext}"
          return result if File.exists?(result)
        end

        # TODO: add also I18n.locale and content_type suffix
        settings.template_cache.fetch(:template, views, name, preferred_ext) do
          exts = Tilt.mappings.keys.join(',')
          candidates = Dir["#{base_path}.{#{exts}}"]
          candidates.detect { |f| File.exists?(f) }
        end
      end

      def find_engine(views, name)
        settings.template_cache.fetch(:engine, views, name) do
          if found = find_template(views, name)
            File.extname(found)[1..-1]
          else raise "Unalble to found template '#{name}' in: #{views}"
          end
        end
      end

      ##
      # Examples:
      #
      #   render '/foo/bar'
      #   # => will look for => /foo/bar.slim etc...
      #   render :bar
      #   # => same as above
      #   render :bar, engine: 'erb'
      #   # => will look for bar.erb
      #   render engine: 'slim', -> { 'h1 Hello' }
      #   # => will render a block in the current provied engine
      #   render text: 'h1 Hello', engine: 'slim'
      #   # => same as above
      #   render slim: 'h1 Hello'
      #   # => same as above
      #
      #
      def render(data, options={}, locals={}, &block)
        # Extract defaults
        if data.is_a?(Hash) && (text = data.delete(:text))
          data, options = proc { text }, data
        end
        engine  = options.delete(:as) || settings.default_engine

        # TODO: Improve look of this
        case data
        when Hash
          k = data.keys[0]
          v = data.delete(k)
          options.merge!(data)
          data, engine = v, k
        when Symbol
          if Tilt[engine]
            data, options = options, {}
          else
            engine = find_engine(options.fetch(:views, settings.views), data)
          end
        when String
          engine = find_engine(options.fetch(:views, settings.views), data)
        else raise "Unable to auto-determine engine from data: #{data}"
        end unless engine

        defaults = settings.respond_to?(:"#{engine}_defaults") ? settings.send(:"#{engine}_defaults") : {}
        options  = defaults.merge(options)

        # Extract generic options
        locals          = options.delete(:locals) || locals         || {}
        views           = options.delete(:views)  || settings.views || './views'
        layout          = options.delete(:layout)
        eat_errors      = layout.nil?
        layout          = settings.default_layout if layout.nil? or layout == true
        content_type    = options.delete(:content_type)  || options.delete(:default_content_type)
        layout_engine   = options.delete(:layout_engine) # || engine
        scope           = options.delete(:scope)         || settings

        # Set some defaults
        options[:outvar]           ||= '@_out_buf'
        options[:default_encoding] ||= settings.default_encoding

        # Compile and render template
        begin
          # TODO: actually, this is not thread safe
          settings.default_layout, layout_was = false, settings.default_layout
          output = compile_template(engine, data, options, views).render(scope, locals, &block)
        ensure
          settings.default_layout = layout_was
        end

        # Render layout
        if layout
          options = options.merge(
            views: views,
            layout: false,
            eat_errors: eat_errors,
            scope: scope,
            as: layout_engine
          )
          catch(:layout_missing) { return render(layout, options, locals) { output } }
        end

        output.extend(ContentTyped).content_type = content_type if content_type
        output
      end

      private
      def compile_template(engine, data, options, views)
        eat_errors = options.delete :eat_errors
        template = Tilt[engine]
        raise "Template engine not found: #{engine}" if template.nil?
        settings.template_cache.fetch(engine, data, options, views) do
          case data
          when Symbol, String
            body, path, line = settings.templates[data]
            if body
              body = body.call if body.respond_to?(:call)
              template.new(path, line.to_i, options) { body }
            else
              file = find_template(views, data, engine.to_s)
              throw :layout_missing if eat_errors and not file
              template.new(file, 1, options)
            end
          when Proc
            path, line = Padrino.first_caller
            template.new(path, line.to_i, options, &data)
          else
            raise ArgumentError, "Sorry, don't know how to render #{data.inspect}."
          end
        end
      end
    end # ClassMethods
  end # Templates
end # Padrino
