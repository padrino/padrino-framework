module Padrino
  module Flash

    class << self
      def registered(app)
        app.helpers Helpers
        app.after do
          session[:_flash] = @_flash.next if @_flash
        end
      end
    end

    class Storage
      include Enumerable

      def initialize(session=nil)
        @now  = session || {}
        @next = {}
      end

      def now
        @now
      end

      def next
        @next
      end

      # @since 0.10.8
      # @api public
      def [](type)
        @now[type]
      end

      # @since 0.10.8
      # @api public
      def []=(type, message)
        @next[type] = message
      end

      # @since 0.10.8
      # @api public
      def delete(type)
        @now.delete(type)
        self
      end

      # @since 0.10.8
      # @api public
      def keys
        @now.keys
      end

      # @since 0.10.8
      # @api public
      def key?(type)
        @now.key?(type)
      end

      # @since 0.10.8
      # @api public
      def each(&block)
        @now.each(&block)
      end

      # @since 0.10.8
      # @api public
      def replace(hash)
        @now.replace(hash)
        self
      end

      # @since 0.10.8
      # @api public
      def update(hash)
        @now.update(hash)
        self
      end
      alias_method :merge!, :update

      # @since 0.10.8
      # @api public
      def sweep
        @now.replace(@next)
        @next = {}
        self
      end

      # @since 0.10.8
      # @api public
      def keep(key = nil)
        if key
          @next[key] = @now[key]
        else
          @next.merge!(@now)
        end
        self
      end

      # @since 0.10.8
      # @api public
      def discard(key = nil)
        if key
          @next.delete(key)
        else
          @next = {}
        end
        self
      end

      # @since 0.10.8
      # @api public
      def clear
        @now.clear
      end

      # @since 0.10.8
      # @api public
      def empty?
        @now.empty?
      end

      # @since 0.10.8
      # @api public
      def to_hash
        @now.dup
      end

      def length
        @now.length
      end
      alias_method :size, :length

      # @since 0.10.8
      # @api public
      def to_s
        @now.to_s
      end

      # @since 0.10.8
      # @api public
      def error=(message)
        self[:error] = message
      end

      # @since 0.10.8
      # @api public
      def error
        self[:error]
      end

      # @since 0.10.8
      # @api public
      def notice=(message)
        self[:notice] = message
      end

      # @since 0.10.8
      # @api public
      def notice
        self[:notice]
      end

      # @since 0.10.8
      # @api public
      def success=(message)
        self[:success] = message
      end

      # @since 0.10.8
      # @api public
      def success
        self[:success]
      end
    end # Storage

    module Helpers
      ##
      # Overloads the existing redirect helper in-order to provide support for flash messages.
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
      #   redirect(dashboard, success: :user_created)
      #   redirect(new_location, 301, notice: 'This page has moved. Please update your bookmarks!!')
      #
      # @since 0.10.8
      # @api public
      def redirect(url, *args)
        flashes = args.extract_options!

        flashes.each do |type, message|
          message = I18n.translate(message) if message.is_a?(Symbol) && defined?(I18n)
          flash[type] = message
        end

        super(url, args)
      end
      alias_method :redirect_to, :redirect

      ##
      # Returns the flash storage object.
      #
      # @return [Storage]
      #
      # @since 0.10.8
      # @api public
      def flash
        @_flash ||= Storage.new(env['rack.session'] ? session[:_flash] : {})
      end
    end
  end
end
