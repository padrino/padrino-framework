require 'mail'

module Mail # @private
  class Message # @private
    include Sinatra::Templates
    include Padrino::Rendering if defined?(Padrino::Rendering)
    include Padrino::Helpers::RenderHelpers if defined? Padrino::Helpers::RenderHelpers
    include Padrino::Helpers if defined?(Padrino::Helpers)
    attr_reader :template_cache
    attr_accessor :mailer_name, :message_name

    def initialize_with_app(*args, &block)
      @template_cache = Sinatra::TemplateCache.new
      # Check if we have an app passed into initialize
      if args[0].respond_to?(:views) && args[0].respond_to?(:reload_templates?)
        app                       = args.shift
        @_views                   = File.join(app.views, 'mailers')
        settings.reload_templates = app.reload_templates?
      else
        @_views = File.expand_path('./mailers')
        settings.reload_templates = true
      end

      initialize_template_settings!

      initialize_without_app(*args, &block)
    end
    alias initialize_without_app initialize
    alias initialize initialize_with_app

    ##
    # Setup like in Sinatra/Padrino apps content_type and template lookup.
    #
    # @example
    #   # This add an email plain part if a template called bar.plain.* is found
    #   # and a HTML part if a template called bar.html.* is found
    #   email do
    #     from     'from@email.com'
    #     to       'to@email.com'
    #     subject  'Welcome here'
    #     provides :plain, :html
    #     render   "foo/bar"
    #   end
    #
    def provides(*formats)
      if formats.empty?
        @_provides ||= []
      else
        @_provides = formats.flatten.compact
      end
    end

    ##
    # Helper to add a text part to a multipart/alternative email. If this and
    # html_part are both defined in a message, then it will be a multipart/alternative
    # message and set itself that way.
    #
    # @example
    #  text_part "Some text"
    #  text_part { render('multipart/basic.text') }
    #
    def text_part(value = nil, &block)
      add_resolved_part(variable: :text_part,
                        value: value,
                        content_type: 'text/plain',
                        &block)
    end

    ##
    # Helper to add a HTML part to a multipart/alternative email. If this and
    # text_part are both defined in a message, then it will be a multipart/alternative
    # message and set itself that way.
    #
    # @example
    #  html_part "Some <b>Html</b> text"
    #  html_part { render('multipart/basic.html') }
    #
    def html_part(value = nil, &block)
      add_resolved_part(variable: :html_part,
                        value: value,
                        content_type: 'text/html',
                        &block)
    end

    def add_resolved_part(attributes = {}, &block)
      variable, value, content_type = attributes.values_at(:variable, :value, :content_type)
      if block_given? || value
        instance_variable_set "@#{variable}", self.part(content_type: content_type,
                                                        body: value,
                                                        part_block: block)
        add_multipart_alternate_header if self.send(variable)
      else
        instance_variable_get("@#{variable}") || find_first_mime_type(content_type)
      end
    end

    ##
    # Allows you to add a part in block form to an existing mail message object.
    #
    # @example
    #  mail = Mail.new do
    #    part content_type: 'multipart/alternative', content_disposition: 'inline' do |p|
    #      p.part content_type: 'text/plain', body: "test text\nline #2"
    #      p.part content_type: 'text/html', body: "<b>test</b> HTML<br/>\nline #2"
    #    end
    #  end
    #
    def part(params = {}, &block)
      part_block = params.delete(:part_block)
      new_part = Mail::Part.new(params)
      new_part.views(@_views)
      new_part.settings.reload_templates = settings.reload_templates?
      new_part.instance_eval(&part_block) if part_block
      yield new_part if block_given?
      add_part(new_part)
      new_part
    end

    def do_delivery_with_logging
      logger.debug "Sending email to: #{destinations.join(' ')}"
      encoded.each_line { |line| logger << "  #{line.strip}" } if logger.debug?
      do_delivery_without_logging
    end

    if Padrino.respond_to?(:logger)
      alias do_delivery_without_logging do_delivery
      alias do_delivery do_delivery_with_logging
    end

    ##
    # Sinatra and Padrino compatibility.
    #
    def settings
      self.class
    end

    ##
    # Sinatra almost compatibility.
    #
    def self.set(name, value)
      singleton_class.class_eval do
        define_method(name) { value } unless method_defined?(name)
      end
    end

    ##
    # Sets the message defined template path to the given view path.
    #
    def views(value)
      @_views = value
      @_mailer_views = false
    end

    ##
    # Sets the local variables available within the message template.
    #
    def locals(value)
      @_locals = value
    end

    ##
    # Returns the templates for this message.
    #
    def self.templates
      @_templates ||= {}
    end

    ##
    # Sets the message defined template path to the given view path.
    #
    def self.views=(value)
      @_views = value
    end

    ##
    # Returns the template view path defined for this message.
    #
    def self.views
      @_views
    end

    ##
    # Modify whether templates should be reloaded (for development).
    #
    def self.reload_templates=(value)
      @_reload_templates = value
    end

    ##
    # Returns true if the templates will be reloaded; false otherwise.
    #
    def self.reload_templates?
      @_reload_templates
    end

    ##
    # Return the path of this file, only for compatibility with Sinatra rendering methods.
    #
    def self.caller_locations
      [[__dir__, 1]]
    end

    ##
    # Return the default encoding.
    #
    def self.default_encoding
      'utf-8'
    end

    ##
    # Modify the default attributes for this message (if not explicitly specified).
    #
    def defaults=(attributes)
      @_defaults = attributes
      @_defaults.each_pair { |k, v| default(k.to_sym, v) } if @_defaults.is_a?(Hash)
    end

    ##
    # Emails have no session to check a token against, so forms in mailer
    # templates are built without a CSRF token.
    #
    def self.protect_from_csrf
      false
    end

    ##
    # The form builder form_for and fields_for use in mailer templates.
    #
    def self.default_builder
      'StandardFormBuilder'
    end

    ##
    # Check if we can log.
    #
    def self.logging?
      @_logging
    end

    def self.logging=(value)
      @_logging = value
    end

    ##
    # Shortcut for delivery_method with smarter SMTP overwrites.
    #
    def via(method = nil, settings = {})
      if method.nil?
        delivery_method
      elsif method.to_sym != :smtp
        delivery_method(method, settings)
      elsif method.to_sym == :smtp && (settings.any? || delivery_method.class.to_s !~ /smtp/i)
        delivery_method(method, settings)
      end
    end

    ##
    # If the value is empty return a symbol that represent the content type so:
    #
    #   "text/plain" => :plain
    #
    # See Padrino::Mailer::Mime for more usage informations.
    #
    def content_type_with_symbol(value = nil)
      value = Padrino::Mailer::Mime::MIME_TYPES.find { |_k, v| v == value }[0] rescue value if value.is_a?(Symbol)
      mime = content_type_without_symbol(value)
      Padrino::Mailer::Mime.mime_type(mime)
    end
    alias content_type_without_symbol content_type
    alias content_type content_type_with_symbol

    private

    ##
    # Defines the render for the mailer utilizing the padrino 'rendering' module
    #
    def render(engine = nil, data = nil, options = {}, locals = {}, &block)
      locals = @_locals || {} if !options[:locals] && locals.empty?
      @template_cache.clear if settings.reload_templates?

      # render(nil, 'template', ...) as RenderHelpers#partial calls it: shift the arguments
      # the way Padrino::Rendering#render does, before defaulting to the message name.
      engine, data, options = data, options, locals if engine.nil? && data && !data.is_a?(Hash)
      engine ||= message_name

      if mailer_name && !engine.to_s.index('/')
        @_views = File.join(@_views, mailer_name.to_s) unless @_mailer_views
        @_mailer_views = true
        engine = engine.to_s.sub(%r{^#{mailer_name}/}, '')
      end

      # Pass the views path per render: class-level settings are shared by every message.
      if data.is_a?(Hash)
        data = { views: @_views }.merge(data)
      else
        options = { views: @_views }.merge(options)
      end

      # A render nested in a template (a partial) returns its output; only the outermost one sets the body.
      return super(engine, data, options, locals, &block) if @_rendering

      begin
        @_rendering = true
        provides.each do |format|
          part do |p|
            p.content_type(format)
            p.send(:render, engine, data, options, locals, &block)
            add_multipart_alternate_header if html_part || provides.include?(:html)
          end
        end

        self.body = super(engine, data, options, locals, &block) if provides.empty?
      ensure
        @_rendering = false
      end
    end

    alias original_partial partial if instance_methods.include?(:partial)
    def partial(template, options = {}, &block)
      raise "gem 'padrino-helpers' is required to render partials" unless respond_to?(:original_partial)
      return original_partial(template, options, &block) if @_rendering

      begin
        @_rendering = true
        output = original_partial(template, options, &block)
      ensure
        @_rendering = false
      end
      self.body = output
    end

    ##
    # Register all special template configurations Padrino has to our fake settings object.
    #
    # The settings object is the message class, so the engine settings go on Mail::Message
    # itself (Mail::Part inherits them). Each is defined once and reads the current
    # configuration, so an engine registered later is picked up by the next message.
    #
    def initialize_template_settings!
      Padrino::Rendering.engine_configurations.each_key do |name|
        next if Message.singleton_class.method_defined?(name, false)

        Message.define_singleton_method(name) { Padrino::Rendering.engine_configurations[name] }
      end
    end
  end
end
