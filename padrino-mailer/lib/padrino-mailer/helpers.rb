module Padrino
  module Mailer
    module Helpers
      def self.included(base) #:nodoc:
        base.extend(ClassMethods)
      end

      ##
      # Delivers an email with the given mail attributes (to, from, subject, cc, bcc, body, et.al)
      #
      # ==== Examples
      #
      #   email do
      #     to @user.email
      #     from "awesomeness@example.com",
      #     subject "Welcome to Awesomeness!"
      #     body 'path/to/my/template', :locals => { :a => a, :b => b }
      #   end
      #
      def email(mail_attributes={}, &block)
        settings.email(mail_attributes, &block)
      end

      ##
      # Delivers a mailer message email with the given attributes
      #
      # ==== Examples
      #
      #   deliver(:sample, :birthday, "Joey", 21)
      #   deliver(:example, :message, "John")
      #
      def deliver(mailer_name, message_name, *attributes)
        settings.deliver(mailer_name, message_name, *attributes)
      end

      module ClassMethods
        def inherited(subclass) #:nodoc:
          @_registered_mailers ||= {}
          super(subclass)
        end

        ##
        # Returns all registered mailers for this application
        #
        def registered_mailers
          @_registered_mailers ||= {}
        end

        ##
        # Defines a mailer object allowing the definition of various email messages that can be delivered
        #
        # ==== Examples
        #
        #   mailer :sample do
        #     email :birthday do |name, age|
        #       subject "Happy Birthday!"
        #       to   'john@fake.com'
        #       from 'noreply@birthday.com'
        #       body render('sample/birthday', :locals => { :name => name, :age => age })
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
        # Delivers a mailer message email with the given attributes
        #
        # ==== Examples
        #
        #   deliver(:sample, :birthday, "Joey", 21)
        #   deliver(:example, :message, "John")
        #
        def deliver(mailer_name, message_name, *attributes)
          registered_mailers[mailer_name].messages[message_name].call(*attributes).deliver
        end

        ##
        # Delivers an email with the given mail attributes (to, from, subject, cc, bcc, body, et.al) using settings of
        # the given app.
        #
        # ==== Examples
        #
        #   MyApp.email(:to => 'to@ma.il', :from => 'from@ma.il', :subject => 'Welcome!', :body => 'Welcome Here!')
        #
        #   # or if you prefer blocks
        #
        #   MyApp.email do
        #     to @user.email
        #     from "awesomeness@example.com",
        #     subject "Welcome to Awesomeness!"
        #     body 'path/to/my/template', :locals => { :a => a, :b => b }
        #   end
        #
        def email(mail_attributes={}, &block)
          message = Mail::Message.new(self)
          message.delivery_method(*delivery_settings)
          message.instance_eval(&block) if block_given?
          mail_attributes.each_pair { |k, v| message.method(k).call(v) }
          message.deliver
        end

        private
          ##
          # Return the parsed delivery method
          #
          def delivery_settings
            @_delivery_setting ||= begin
              return [:sendmail, {}] unless respond_to?(:delivery_method)
              return [delivery_method.keys[0], delivery_method.values[0]] if delivery_method.is_a?(Hash)
              return [delivery_method, {}] if delivery_method.is_a?(Symbol)
              [nil, {}]
            end
          end
      end
    end # Helpers
  end # Mailer
end # Padrino