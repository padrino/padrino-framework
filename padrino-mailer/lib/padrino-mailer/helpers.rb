module Padrino
  module Mailer
    ##
    # Helpers for defining and delivering email messages.
    #
    module Helpers
      def self.included(base) # @private
        base.extend(ClassMethods)
      end

      ##
      # Delivers an email with the given mail attributes.
      #
      # @param [Hash] mail_attributes
      #   The attributes for this message (to, from, subject, cc, bcc, body, etc).
      # @param [Proc] block
      #   The block mail attributes for this message.
      #
      # @example
      #   email do
      #     to      @user.email
      #     from    "awesomeness@example.com"
      #     subject "Welcome to Awesomeness!"
      #     locals  :a => a, :b => b
      #     render  'path/to/my/template'
      #   end
      #
      # @see ClassMethods#email
      def email(mail_attributes={}, &block)
        settings.email(mail_attributes, &block)
      end

      ##
      # Delivers a mailer message email with the given attributes.
      #
      # @param [Symbol] mailer_name
      #   The name of the mailer.
      # @param [Symbol] message_name
      #   The name of the message to deliver.
      # @param attributes
      #   The parameters to pass to the mailer.
      #
      # @example
      #   deliver(:sample, :birthday, "Joey", 21)
      #   deliver(:example, :message, "John")
      #
      # @see ClassMethods#deliver
      def deliver(mailer_name, message_name, *attributes)
        settings.deliver(mailer_name, message_name, *attributes)
      end

      # Class methods responsible for registering mailers, configuring
      # settings and delivering messages.
      #
      module ClassMethods
        def inherited(subclass)
          @_registered_mailers ||= {}
          super(subclass)
        end

        ##
        # Returns all registered mailers for this application.
        #
        def registered_mailers
          @_registered_mailers ||= {}
        end

        ##
        # Defines a mailer object allowing the definition of various
        # email messages that can be delivered.
        #
        # @param [Symbol] name
        #   The name of the mailer to initialize.
        #
        # @example
        #   mailer :sample do
        #     email :birthday do |name, age|
        #       subject 'Happy Birthday!'
        #       to      'john@fake.com'
        #       from    'noreply@birthday.com'
        #       locals  :name => name, :age => age
        #       render  'sample/birthday'
        #     end
        #   end
        #
        def mailer(name, &block)
          mailer                   = Padrino::Mailer::Base.new(self, name, &block)
          mailer.delivery_settings = delivery_settings
          registered_mailers[name] = mailer
          mailer
        end
        alias :mailers :mailer

        ##
        # Delivers a mailer message email with the given attributes.
        #
        # @param [Symbol] mailer_name
        #   The name of the mailer.
        # @param [Symbol] message_name
        #   The name of the message to deliver.
        # @param attributes
        #   The parameters to pass to the mailer.
        #
        # @example
        #   deliver(:sample, :birthday, "Joey", 21)
        #   deliver(:example, :message, "John")
        #
        def deliver(mailer_name, message_name, *attributes)
          mailer = registered_mailers[mailer_name] or fail "mailer '#{mailer_name}' is not registered"
          message = mailer.messages[message_name] or fail "mailer '#{mailer_name}' has no message '#{message_name}'"
          message = message.call(*attributes)
          message.delivery_method(*delivery_settings)
          message.deliver
        end

        ##
        # Delivers an email with the given mail attributes with specified and default settings.
        #
        # @param [Hash] mail_attributes
        #   The attributes for this message (to, from, subject, cc, bcc, body, etc.).
        # @param [Proc] block
        #   The block mail attributes for this message.
        #
        # @example
        #   MyApp.email(:to => 'to@ma.il', :from => 'from@ma.il', :subject => 'Welcome!', :body => 'Welcome Here!')
        #
        #   # or if you prefer blocks
        #
        #   MyApp.email do
        #     to @user.email
        #     from "awesomeness@example.com"
        #     subject "Welcome to Awesomeness!"
        #     body 'path/to/my/template', :locals => { :a => a, :b => b }
        #   end
        #
        def email(mail_attributes={}, &block)
          message = _padrino_mailer::Message.new(self)
          message.delivery_method(*delivery_settings)
          message.instance_eval(&block) if block_given?
          mail_attributes = mailer_defaults.merge(mail_attributes) if respond_to?(:mailer_defaults)
          mail_attributes.each_pair { |k, v| message.method(k).call(v) }
          message.deliver
        end

        private
        ##
        # Returns the parsed delivery method options.
        #
        def delivery_settings
          @_delivery_setting ||= begin
            if Gem.win_platform? && !respond_to?(:delivery_method)
              raise "To use mailers on Windows you must set a :delivery_method, see http://padrinorb.com/guides/features/padrino-mailer/#configuration"
            end

            return [:sendmail, { :location => `which sendmail`.chomp }] unless respond_to?(:delivery_method)
            return [delivery_method.keys[0], delivery_method.values[0]] if delivery_method.is_a?(Hash)
            return [delivery_method, {}] if delivery_method.is_a?(Symbol)
            [nil, {}]
          end
        end
      end
    end
  end
end
