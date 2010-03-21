module Padrino
  module Mailer
    ##
    # This is the abstract class that other mailers will inherit from in order to send mail
    #
    # You can set the default delivery settings through:
    #
    #   Padrino::Mailer::Base.smtp_settings = {
    #     :host   => 'smtp.yourserver.com',
    #     :port   => '25',
    #     :user   => 'user',
    #     :pass   => 'pass',
    #     :auth   => :plain # :plain, :login, :cram_md5, no auth by default
    #     :domain => "localhost.localdomain" # the HELO domain provided by the client to the server
    #   }
    #
    # and then all delivered mail will use these settings unless otherwise specified.
    #
    class Base
      ##
      # Returns the available mail fields when composing a message
      #
      def self.mail_fields
        [:to, :cc, :bcc, :reply_to, :from, :subject, :content_type, :charset, :via, :attachments]
      end

      @@views_path = []
      cattr_accessor :smtp_settings
      cattr_accessor :views_path
      attr_accessor :mail_attributes

      def initialize(mail_name=nil) #:nodoc:
        @mail_name = mail_name
        @mail_attributes = {}
      end

      ##
      # Defines a method allowing mail attributes to be set into a hash for use when delivering
      #
      self.mail_fields.each do |field|
        define_method(field) { |value| @mail_attributes[field] = value }
      end

      ##
      # Assigns the body key to the mail attributes either with the rendered body from a template or the given string value
      #
      def body(body_value)
        template = template_path
        raise "Template for '#{@mail_name}' could not be located in views path!" unless template
        @mail_attributes[:body] = Tilt.new(template).render(self, body_value.symbolize_keys) if body_value.is_a?(Hash)
        @mail_attributes[:body] = body_value if body_value.is_a?(String)
      end

      ##
      # Returns the path to the email template searched for using glob pattern
      #
      def template_path
        self.views_path.each do |path|
          template = Dir[File.join(path, self.class.name.underscore.split("/").last, "#{@mail_name}.*")].first
          return template if template
        end
      end

      ##
      # Delivers the specified message for mail_name to the intended recipients
      # mail_name corresponds to the name of a defined method within the mailer class
      #
      # ==== Examples
      #
      #   SampleMailer.deliver(:birthday_message)
      #
      def self.deliver(mail_name, *args)
        mail_object = self.new(mail_name)
        mail_object.method(mail_name).call(*args)
        MailObject.new(mail_object.mail_attributes, self.smtp_settings).deliver
      end

      ##
      # Returns true if a mail exists with the name being delivered
      #
      def self.respond_to?(method_sym, include_private = false)
        method_sym.to_s =~ /deliver_(.*)/ ? self.method_defined?($1) : super(method_sym, include_private)
      end

      ##
      # Handles method missing for a mailer class. Delivers a message based on the method
      # being called i.e #deliver_birthday_message(22) invokes #birthday_message(22) to setup mail object
      #
      def self.method_missing(method_sym, *arguments, &block)
        method_sym.to_s =~ /deliver_(.*)/ ? self.deliver($1, *arguments) : super(method_sym, *arguments, &block)
      end
    end # Base
  end # Mailer
end # Padrino