# encoding: UTF-8
module Padrino
  module Flash
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
          content_tag(:div, flash[type], :id => "flash-#{type}", :title => t(type.to_s.titleize), :class => type)
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