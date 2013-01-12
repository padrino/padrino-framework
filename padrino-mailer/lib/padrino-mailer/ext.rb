module Mail # @private
  class Message # @private
    include Sinatra::Templates
    include Padrino::Rendering if defined?(Padrino::Rendering)
    attr_reader :template_cache

    def initialize_with_app(*args, &block)
      @template_cache = Tilt::Cache.new
      # Check if we have an app passed into initialize
      if args[0].respond_to?(:views) && args[0].respond_to?(:reload_templates?)
        app                       = args.shift
        settings.views            = File.join(app.views, 'mailers')
        settings.reload_templates = app.reload_templates?
      else
        # Set a default view for this class
        settings.views = File.expand_path("./mailers")
        settings.reload_templates = true
      end
      # Run the original initialize
      initialize_without_app(*args, &block)
    end
    alias_method_chain :initialize, :app

    ##
    # Setup like in Sinatra/Padrino apps content_type and template lookup.
    #
    # @example
    #   # This add a email plain part if a template called bar.plain.* is found
    #   # and a html part if a template called bar.html.* is found
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
    # Helper to add a text part to a multipart/alternative email.  If this and
    # html_part are both defined in a message, then it will be a multipart/alternative
    # message and set itself that way.
    #
    # @example
    #  text_part "Some text"
    #  text_part { render('multipart/basic.text') }
    #
    def text_part(value=nil, &block)
      if block_given? || value
        @text_part = self.part(:content_type => "text/plain", :body => value, :part_block => block)
        add_multipart_alternate_header unless html_part.blank?
      else
        @text_part || find_first_mime_type("text/plain")
      end
    end

    ##
    # Helper to add a html part to a multipart/alternative email.  If this and
    # text_part are both defined in a message, then it will be a multipart/alternative
    # message and set itself that way.
    #
    # @example
    #  html_part "Some <b>Html</b> text"
    #  html_part { render('multipart/basic.html') }
    #
    def html_part(value=nil, &block)
      if block_given? || value
        @html_part = self.part(:content_type => "text/html", :body => value, :part_block => block)
        add_multipart_alternate_header unless text_part.blank?
      else
        @html_part || find_first_mime_type("text/html")
      end
    end

    ##
    # Allows you to add a part in block form to an existing mail message object
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
    end

    def do_delivery_with_logging
      logger.debug "Sending email to: #{destinations.join(" ")}"
      encoded.to_lf.split("\n").each { |line| logger << ("  " + line) } if logger.debug?
      do_delivery_without_logging
    end
    alias_method_chain :do_delivery, :logging if Padrino.respond_to?(:logger)

    ##
    # Sinatra and Padrino compatibility
    #
    def settings
      self.class
    end

    ##
    # Sets the message defined template path to the given view path
    #
    def views(value)
      settings.views = value
    end

    ##
    # Sets the local variables available within the message template
    #
    def locals(value)
      @_locals = value
    end

    ##
    # Returns the templates for this message
    #
    def self.templates
      @_templates ||= {}
    end

    ##
    # Sets the message defined template path to the given view path
    #
    def self.views=(value)
      @_views = value
    end

    ##
    # Returns the template view path defined for this message
    #
    def self.views
      @_views
    end

    ##
    # Modify whether templates should be reloaded (for development)
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
    # Return the path of this file, only for compatiblity with sinatra rendering methods
    #
    def self.caller_locations
      [[File.dirname(__FILE__), 1]]
    end

    ##
    # Return the default encoding
    #
    def self.default_encoding
      "utf-8"
    end

    ##
    # Modify the default attributes for this message (if not explicitly specified)
    #
    def defaults=(attributes)
      @_defaults = attributes
      @_defaults.each_pair { |k, v| default(k.to_sym, v) } if @_defaults.is_a?(Hash)
    end

    ##
    # Check if we can log
    #
    def self.logging?
      @_logging
    end

    def self.logging=(value)
      @_logging = value
    end

    # Shortcut for delivery_method with smarter smtp overwrites
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
    # If the value is empty return a symbol that rappresent the content type so:
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
    alias_method_chain :content_type, :symbol

    private

      # Defines the render for the mailer utilizing the padrino 'rendering' module
      def render(engine, data=nil, options={}, locals={}, &block)
        locals = @_locals if options[:locals].blank? && locals.blank?
        # Reload templates
        @template_cache.clear if settings.reload_templates?
        # Setup provides
        provides.each do |format|
          part do |p|
            p.content_type(format)
            p.send(:render, engine, data, options, locals, &block)
            add_multipart_alternate_header if html_part.present? || provides.include?(:html)
          end
        end
        # Setup the body if we don't have provides
        self.body = super(engine, data, options, locals, &block) if provides.empty?
      end

  end # Message
end # Mail
