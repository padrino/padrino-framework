require 'mail'

module Mail # @private
  class Message # @private
    include Sinatra::Templates
    include Padrino::Rendering if defined?(Padrino::Rendering)
    include Padrino::Helpers::RenderHelpers if defined? Padrino::Helpers::RenderHelpers
    attr_reader :template_cache
    attr_accessor :mailer_name, :message_name

    def initialize_with_app(*args, &block)
      @template_cache = Tilt::Cache.new
      # Check if we have an app passed into initialize
      if args[0].respond_to?(:views) && args[0].respond_to?(:reload_templates?)
        app                       = args.shift
        settings.views            = File.join(app.views, 'mailers')
        settings.reload_templates = app.reload_templates?
      else
        settings.views = File.expand_path("./mailers")
        settings.reload_templates = true
      end

      initialize_template_settings!

      initialize_without_app(*args, &block)
    end
    alias_method :initialize_without_app, :initialize
    alias_method :initialize, :initialize_with_app

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
      add_resolved_part(:variable     => :text_part,
                        :value        => value,
                        :content_type => 'text/plain',
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
      add_resolved_part(:variable     => :html_part,
                        :value        => value,
                        :content_type => 'text/html',
                        &block)
    end

    def add_resolved_part(attributes = {}, &block)
      variable, value, content_type = attributes.values_at(:variable, :value, :content_type)
      if block_given? || value
        instance_variable_set "@#{variable}", self.part(:content_type => content_type,
                                                        :body => value,
                                                        :part_block => block)
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
    #    part :content_type => "multipart/alternative", :content_disposition => "inline" do |p|
    #      p.part :content_type => "text/plain", :body => "test text\nline #2"
    #      p.part :content_type => "text/html", :body => "<b>test</b> HTML<br/>\nline #2"
    #    end
    #  end
    #
    def part(params = {}, &block)
      part_block = params.delete(:part_block)
      new_part = Mail::Part.new(params)
      new_part.settings.views = settings.views
      new_part.settings.reload_templates = settings.reload_templates?
      new_part.instance_eval(&part_block) if part_block
      yield new_part if block_given?
      add_part(new_part)
      new_part
    end

    def do_delivery_with_logging
      logger.debug "Sending email to: #{destinations.join(" ")}"
      encoded.each_line { |line| logger << ("  " + line.strip) } if logger.debug?
      do_delivery_without_logging
    end
    if Padrino.respond_to?(:logger)
      alias_method :do_delivery_without_logging, :do_delivery
      alias_method :do_delivery, :do_delivery_with_logging
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
      self.class.instance_eval{ define_method(name) { value } unless method_defined?(:erb) }
    end

    ##
    # Sets the message defined template path to the given view path.
    #
    def views(value)
      settings.views = value
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
      [[File.dirname(__FILE__), 1]]
    end

    ##
    # Return the default encoding.
    #
    def self.default_encoding
      "utf-8"
    end

    ##
    # Modify the default attributes for this message (if not explicitly specified).
    #
    def defaults=(attributes)
      @_defaults = attributes
      @_defaults.each_pair { |k, v| default(k.to_sym, v) } if @_defaults.is_a?(Hash)
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
    def content_type_with_symbol(value=nil)
      value = Padrino::Mailer::Mime::MIME_TYPES.find { |k,v| v == value }[0] rescue value if value.is_a?(Symbol)
      mime = content_type_without_symbol(value)
      Padrino::Mailer::Mime.mime_type(mime)
    end
    alias_method :content_type_without_symbol, :content_type
    alias_method :content_type, :content_type_with_symbol

    private

    ##
    # Defines the render for the mailer utilizing the padrino 'rendering' module
    #
    def render(engine=nil, data=nil, options={}, locals={}, &block)
      locals = @_locals || {} if !options[:locals] && locals.empty?
      @template_cache.clear if settings.reload_templates?

      engine ||= message_name

      if mailer_name && !engine.to_s.index('/')
        settings.views += "/#{mailer_name}" unless settings.views.include?("/#{mailer_name}")
        engine = engine.to_s.sub(%r{^#{mailer_name}/}, '')
      end

      provides.each do |format|
        part do |p|
          p.content_type(format)
          p.send(:render, engine, data, options, locals, &block)
          add_multipart_alternate_header if html_part || provides.include?(:html)
        end
      end

      self.body = super(engine, data, options, locals, &block) if provides.empty?
    end

    alias_method :original_partial, :partial if instance_methods.include?(:partial)
    def partial(template, options={}, &block)
      raise "gem 'padrino-helpers' is required to render partials" unless respond_to?(:original_partial)
      self.body = original_partial(template, options, &block)
    end

    ##
    # Register all special template configurations Padrino has to our fake settings object.
    #
    def initialize_template_settings!
      Padrino::Rendering.engine_configurations.each do |name, value|
        settings.class.instance_eval { define_method(name) { value } }
      end
    end
  end
end
