# require tilt if available; fall back on bundled version.
begin
  require 'tilt'
rescue LoadError
  require 'sinatra/tilt'
end
require 'padrino-core/support_lite'

Dir[File.dirname(__FILE__) + '/padrino-mailer/**/*.rb'].each { |file| require file }

module Padrino
  ##
  # This component uses the 'mail' library to create a powerful but simple mailer system within Padrino (and Sinatra).
  # There is full support for using plain or html content types as well as for attaching files.
  # The MailerPlugin has many similarities to ActionMailer but is much lighterweight and (arguably) easier to use.
  #
  module Mailer
    ##
    # Used Padrino::Application for register Padrino::Mailer::Base::views_path
    #
    def self.registered(app)
      Padrino::Mailer::Base::views_path << app.views
      app.helpers Padrino::Mailer::Helpers
    end
    
    module Helpers
      ##
      # Delivers an email with the given mail attributes (to, from, subject, cc, bcc, body, et.al)
      #
      # ==== Examples
      #
      #   email :to => @user.email, :from => "awesomeness@example.com", 
      #         :subject => "Welcome to Awesomeness!", :body => haml(:some_template)
      #
      def email(mail_attributes)
        smtp_settings = Padrino::Mailer::Base.smtp_settings
        Padrino::Mailer::MailObject.new(mail_attributes, smtp_settings).deliver
      end
    end
  end # Mailer
end # Padrino