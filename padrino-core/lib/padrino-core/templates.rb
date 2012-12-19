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
      base.extend(ClassMethods)
      base.init_templates!
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
        return if self == Padrino::Application
        send :include, Settings               unless respond_to?(:settings)
        set :views, './views'                 unless respond_to?(:views)
        set :default_encoding, 'utf-8'        unless respond_to?(:default_encoding)
        set :templates, {}                    unless respond_to?(:templates)
        set :template_cache, Tilt::Cache.new  unless respond_to?(:template_cache)
        set :default_layout, :layout
      end

      def inherited(base)
        base.init_templates!
        super
      end

      ENGINES.each do |engine, default|
        define_method(engine) do |tpl, opts=default, loc={}, &bk|
          render(engine, tpl, opts, loc, &bk)
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

      # Calls the given block for every possible template file in views,
      # named name.ext, where ext is registered on engine.
      def find_template(views, name, engine, ext)
        yield File.join(views, "#{name}.#{ext}") # try first preferred ext
        Tilt.mappings.each do |e, engines|       # try other extensions
          next unless e != ext and engines.include?(engine)
          yield File.join(views, "#{name}.#{e}")
        end
      end

      # logic shared between builder and nokogiri
      def render_ruby(engine, template, options={}, locals={}, &block)
        options, template = template, nil if template.is_a?(Hash)
        template = Proc.new { block } if template.nil?
        render engine, template, options, locals
      end

      def render(engine, data, options={}, locals={}, &block)
        # extract generic options
        locals          = options.delete(:locals) || locals         || {}
        views           = options.delete(:views)  || settings.views || "./views"
        layout          = options.delete(:layout)
        eat_errors      = layout.nil?
        layout          = settings.default_layout   if layout.nil? or layout == true
        content_type    = options.delete(:content_type)  || options.delete(:default_content_type)
        layout_engine   = options.delete(:layout_engine) || engine
        scope           = options.delete(:scope)         || settings

        # set some defaults
        options[:outvar]           ||= '@_out_buf'
        options[:default_encoding] ||= settings.default_encoding

        # compile and render template
        begin
          # TODO: check thread safety
          layout_was = settings.default_layout
          settings.default_layout = false
          template = compile_template(engine, data, options, views)
          output = template.render(scope, locals, &block)
        ensure
          settings.default_layout = layout_was
        end

        # render layout
        if layout
          options = options.merge(views: views, layout: false, eat_errors: eat_errors, scope: scope)
          catch(:layout_missing) { return render(layout_engine, layout, options, locals) { output } }
        end

        output.extend(ContentTyped).content_type = content_type if content_type
        output
      end

      private
      def compile_template(engine, data, options, views)
        eat_errors = options.delete :eat_errors
        settings.template_cache.fetch(engine, data, options) do
          template = Tilt[engine]
          raise "Template engine not found: #{engine}" if template.nil?

          case data
          when Symbol
            body, path, line = settings.templates[data]
            if body
              body = body.call if body.respond_to?(:call)
              template.new(path, line.to_i, options) { body }
            else
              found = false
              find_template(views, data, template, engine.to_s) do |file|
                path ||= file # keep the initial path rather than the last one
                if found = File.exists?(file)
                  path = file
                  break
                end
              end
              throw :layout_missing if eat_errors and not found
              template.new(path, 1, options)
            end
          when Proc, String
            body = data.is_a?(String) ? Proc.new { data } : data
            path, line = Padrino.first_caller
            template.new(path, line.to_i, options, &body)
          else
            raise ArgumentError, "Sorry, don't know how to render #{data.inspect}."
          end
        end
      end
    end # ClassMethods
  end # Templates
end # Padrino
