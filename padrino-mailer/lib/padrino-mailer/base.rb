module Padrino
  module Mailer
    ##
    # This is the abstract class that other mailers will inherit from in order to send mail
    #
    # You can set the default delivery settings from your app through:
    #
    #   set :delivery_method, :smtp => {
    #     :address         => 'smtp.yourserver.com',
    #     :port            => '25',
    #     :user_name       => 'user',
    #     :password        => 'pass',
    #     :authentication  => :plain # :plain, :login, :cram_md5, no auth by default
    #     :domain          => "localhost.localdomain" # the HELO domain provided by the client to the server
    #   }
    #
    # or sendmail:
    #
    #   set :delivery_method, :sendmail
    #
    # or for tests:
    #
    #   set :delivery_method, :test
    #
    # and then all delivered mail will use these settings unless otherwise specified.
    #
    class Base
      attr_accessor :delivery_settings, :app, :mailer_name, :messages

      def initialize(app, name, &block) #:nodoc:
        @mailer_name = name
        @messages    = {}
        @defaults    = {}
        @app         = app
        instance_eval(&block)
      end

      ##
      # Defines a mailer object allowing the definition of various email messages that can be delivered
      #
      # ==== Examples
      #
      #   email :birthday do |name, age|
      #     subject "Happy Birthday!"
      #     to   'john@fake.com'
      #     from 'noreply@birthday.com'
      #     body 'name' => name, 'age' => age
      #   end
      #
      def email(name, &block)
        raise "The email '#{name}' is already defined" if self.messages[name].present?
        self.messages[name] = Proc.new { |*attrs|
          message = Mail::Message.new(self.app)
          message.defaults = self.defaults if self.defaults.any?
          message.delivery_method(*delivery_settings)
          message.instance_exec(*attrs, &block)
          message
        }
      end
      alias :message :email
      
      # Defines the default attributes for a message in this mailer (including app-wide defaults)
      # 
      # ==== Examples
      #
      #   mailer :alternate do
      #    defaults :from => 'padrino@from.com', :to => 'padrino@to.com'
      #    email(:foo) do ... end
      #  end
      # 
      def defaults(attributes=nil)
        if attributes.nil? # Retrieve the default values
          @app.respond_to?(:mailer_defaults) ? @app.mailer_defaults.merge(@defaults) : @defaults
        else # updates the default values
          @defaults = attributes
        end
      end
    end # Base
  end # Mailer
end # Padrino