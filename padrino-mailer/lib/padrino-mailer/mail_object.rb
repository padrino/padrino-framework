module Padrino
  module Mailer
    ##
    # This represents a particular mail object which will need to be sent
    # A mail_object requires the mail attributes and the delivery_settings
    #
    class MailObject
      ##
      # Initialize a new MailObject
      #
      # ==== Examples
      #
      #   Padrino::Mailer::MailObject.new(
      #     :subject => "Hey this is my subject",
      #     :to => "info@padrinorb.org",
      #     :from => "foo@bar.com",
      #     :body => "This is my body"
      #   ).deliver
      #
      def initialize(mail_attributes={}, smtp_settings={})
        @mail_attributes = mail_attributes.dup
        @smtp_settings = smtp_settings.dup if smtp_settings.present?
      end

      ##
      # Constructs the delivery attributes for the message and then sends the mail
      #
      # ==== Examples
      #
      #   @mail_object.deliver
      #
      def deliver
        @mail_attributes.reverse_merge!(:via => self.delivery_method.to_sym)
        @mail_attributes.reverse_merge!(:smtp => @smtp_settings) if using_smtp?
        self.send_mail(@mail_attributes)
      end

      protected
        ##
        # Returns the delivery method to use for this mail object
        #
        # ==== Examples
        #
        # @mo.delivery_method => :smtp || :sendmail
        #
        def delivery_method
          @mail_attributes[:via] || (@smtp_settings.present? ? :smtp : :sendmail)
        end

        ##
        # Returns true if the mail object is going to be delivered using smtp
        #
        def using_smtp?
          delivery_method.to_s =~ /smtp/
        end

        ##
        # Performs the actual email sending
        #
        def send_mail(delivery_attributes)
          Delivery.mail(delivery_attributes) && true
        end
    end # MailObject
  end # Mailer
end # Padrino
