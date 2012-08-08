# encoding: utf-8

module Padrino
  module Flash

    class << self
      # @private
      def registered(app)
        app.helpers Helpers
        app.enable :sessions
        app.enable :flash

        app.after do
          session[:_flash] = @_flash.next if @_flash && app.flash?
        end
      end
    end # self
    
    class Storage
      include Enumerable

      attr_reader :now
      attr_reader :next

      # @private
      def initialize(session)
        @now  = session || {}
        @next = {}
      end

      # @since 0.1.0
      # @api public
      def [](type)
        @now[type]
      end

      # @since 0.1.0
      # @api public
      def []=(type, message)
        @next[type] = message
      end

      # @since 0.1.0
      # @api public
      def delete(type)
        @now.delete(type)
        self
      end

      # @since 0.1.0
      # @api public
      def keys
        @now.keys
      end

      # @since 0.1.0
      # @api public
      def key?(type)
        @now.key?(type)
      end

      # @since 0.1.0
      # @api public
      def each(&block)
        @now.each(&block)
      end

      # @since 0.1.0
      # @api public
      def replace(hash)
        @now.replace(hash)
        self
      end

      # @since 0.1.0
      # @api public
      def update(hash)
        @now.update(hash)
        self
      end
      alias_method :merge!, :update

      # @since 0.1.0
      # @api public
      def sweep
        @now.replace(@next)
        @next = {}
        self
      end

      # @since 0.1.0
      # @api public
      def keep(key = nil)
        if key
          @next[key] = @now[key]
        else
          @next.merge!(@now)
        end
      end

      # @since 0.1.0
      # @api public
      def discard(key = nil)
        if key
          @next.delete(key)
        else
          @next = {}
        end
      end

      # @since 0.1.0
      # @api public
      def clear
        @now.clear
      end

      # @since 0.1.0
      # @api public
      def empty?
        @now.empty?
      end

      # @since 0.1.0
      # @api public
      def to_hash
        @now.dup
      end

      # @since 0.1.0
      # @api public
      def to_s
        @now.to_s
      end

      # @since 0.1.0
      # @api public
      def error=(message)
        self[:error] = message
      end

      # @since 0.1.0
      # @api public
      def error
        self[:error]
      end

      # @since 0.1.0
      # @api public
      def notice=(message)
        self[:notice] = message
      end

      # @since 0.1.0
      # @api public
      def notice
        self[:notice]
      end

      # @since 0.1.0
      # @api public
      def success=(message)
        self[:success] = message
      end

      # @since 0.1.0
      # @api public
      def success
        self[:success]
      end
    end # Storage    
    
    module Helpers
      ###
      # Overloads the existing redirect helper in-order to provide support for flash messages
      #
      # @overload redirect(url)
      #   @param [String] url
      #
      # @overload redirect(url, status_code)
      #   @param [String] url
      #   @param [Fixnum] status_code
      #
      # @overload redirect(url, status_code, flash_messages)
      #   @param [String] url
      #   @param [Fixnum] status_code
      #   @param [Hash]   flash_messages
      #
      # @overload redirect(url, flash_messages)
      #   @param [String] url
      #   @param [Hash]   flash_messages
      #
      # @example
      #   redirect(dashboard, :success => :user_created)
      #   redirect(new_location, 301, notice: 'This page has moved. Please update your bookmarks!!')
      #
      # @since 0.1.0
      # @api public
      def redirect(url, *args)
        flashes = args.extract_options!

        flashes.each do |type, message|
          message = I18n.translate(message) if message.is_a?(Symbol)
          flash[type] = message
        end

        super(url, args)
      end
      alias_method :redirect_to, :redirect

      ###
      # Returns HTML tags to display the current flash messages
      #
      # @return [String]
      #   Generated HTML for flash messages
      #
      # @example
      #   flash_messages
      #   # => <div id="flash">
      #   # =>   <span class="warning" title="Warning">Danger, Will Robinson!</span>
      #   # => </div>
      #
      # @since 0.1.0
      # @api public
      def flash_messages
        flashes = flash.collect do |type, message|
          content_tag(:span, message, :title => type.to_s.titleize, :class => type)
        end.join("\n")

        # Create the tag even if we don't need it so it can be dynamically altered
        content_tag(:div, flashes, :id => 'flash')
      end

      ###
      # Returns an HTML div to display the specified flash if it exists
      #
      # @return [String]
      #   Generated HTML for the specified flash message
      #
      # @example
      #   flash_message :error
      #   # => <div id="flash-error" title="Error" class="error">
      #   # =>   Invalid Handle/Password Combination
      #   # => </div>
      #
      #   flash_message :success
      #   # => <div id="flash-success" title="Success" class="success">
      #   # =>   Your account has been successfully registered!
      #   # => </div>
      #
      # @since 0.1.0
      # @api public
      def flash_message(type)
        if flash[type]
          content_tag(:div, flash[type], :id => "flash-#{type}", :title => type.to_s.titleize, :class => type)
        end
      end

      ###
      # Returns the flash storage object
      #
      # @return [Storage]
      #
      # @since 0.1.0
      # @api public
      def flash
        @_flash ||= Storage.new(session[:_flash])
      end
    end # Helpers
   
  end # Flash
end # Padrino