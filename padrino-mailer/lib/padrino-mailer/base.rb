module Padrino
  module Mailer
    ##
    # This is the abstract class that other mailers will inherit from in order to send mail.
    #
    # You can set the default delivery settings from your app through:
    #
    #  set :delivery_method, :smtp => {
    #    :address         => 'smtp.yourserver.com',
    #    :port            => '25',
    #    :user_name       => 'user',
    #    :password        => 'pass',
    #    :authentication  => :plain
    #  }
    #
    # or sendmail:
    #
    #  set :delivery_method, :sendmail
    #
    # or for tests:
    #
    #  set :delivery_method, :test
    #
    # and all delivered mail will use these settings unless otherwise specified.
    #
    # Define a mailer in your application:
    #
    #   # app/mailers/sample_mailer.rb
    #   MyAppName.mailers :sample do
    #     defaults :content_type => 'html'
    #     email :registration do |name, age|
    #       to      'user@domain.com'
    #       from    'admin@site.com'
    #       subject 'Welcome to the site!'
    #       locals  :name => name
    #       render  'registration'
    #     end
    #   end
    #
    # Use the mailer to deliver messages:
    #
    #  deliver(:sample, :registration, "Bob", "21")
    #
    class Base
      attr_accessor :delivery_settings, :app, :mailer_name, :messages

      ##
      # Constructs a +Mailer+ base object with specified options.
      #
      # @param [Sinatra::Application] app
      #   The application tied to this mailer.
      # @param [Symbol] name
      #   The name of this mailer.
      # @param [Proc] block
      #   The +email+ definitions block.
      #
      # @see Padrino::Mailer::Helpers::ClassMethods#mailer
      def initialize(app, name, &block)
        @mailer_name = name
        @messages    = {}
        @defaults    = {}
        @app         = app
        instance_eval(&block)
      end

      # Defines a mailer object allowing the definition of various email
      # messages that can be delivered.
      #
      # @param [Symbol] name
      #   The name of this email message.
      # @param [Proc] block
      #   The message definition (i.e subject, to, from, locals).
      #
      # @example
      #   email :birthday do |name, age|
      #     subject "Happy Birthday!"
      #     to   'john@fake.com'
      #     from 'noreply@birthday.com'
      #     locals 'name' => name, 'age' => age
      #     render 'birthday'
      #   end
      #
      def email(name, &block)
        raise "The email '#{name}' is already defined" if self.messages[name]
        self.messages[name] = Proc.new { |*attrs|
          message = app.settings._padrino_mailer::Message.new(self.app)
          message.mailer_name = mailer_name
          message.message_name = name
          message.defaults = self.defaults if self.defaults.any?
          message.delivery_method(*delivery_settings)
          message.instance_exec(*attrs, &block)
          message
        }
      end
      alias :message :email

      # Defines the default attributes for a message in this mailer
      # (including app-wide defaults).
      #
      # @param [Hash] attributes
      #   The hash of message options to use as default.
      #
      # @example
      #   mailer :alternate do
      #     defaults :from => 'padrino@from.com', :to => 'padrino@to.com'
      #     email(:foo) do; end
      #   end
      #
      def defaults(attributes=nil)
        if attributes.nil? # Retrieve the default values
          @app.respond_to?(:mailer_defaults) ? @app.mailer_defaults.merge(@defaults) : @defaults
        else # updates the default values
          @defaults = attributes
        end
      end
    end
  end
end
