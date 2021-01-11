begin
  require 'tilt'
rescue LoadError
  require 'sinatra/tilt'
end

module Padrino
  ##
  # This component uses the +mail+ library to create a powerful but simple
  # mailer within Padrino (and Sinatra).
  # There is full support for using plain or html content-types as well as for file attachments.
  #
  # Using the mailer in Padrino has two forms. The 'quick' method requires only use
  # of the +email+ method directly in the controller:
  #
  #  # app/controllers/session.rb
  #  post :create do
  #    email do
  #      from "tony@reyes.com"
  #      to "john@smith.com"
  #      subject "Welcome!"
  #      body render('email/registered')
  #    end
  #  end
  #
  module Mailer
    class << self
      ##
      # Registers the Padrino::Mailer helpers with the application.
      #
      # @param [Sinatra::Application] app The application that needs mailers.
      #
      # @example
      #   require 'padrino-mailer'
      #   class Demo < Padrino::Application
      #     register Padrino::Mailer::Helpers
      #   end
      #
      def registered(app)
        require 'padrino-mailer/base'
        require 'padrino-mailer/helpers'
        require 'padrino-mailer/mime'
        # This lazily loads the mail gem, due to its long require time.
        app.set :_padrino_mailer, proc {
          require 'padrino-mailer/ext'
          app._padrino_mailer = Mail
        }
        app.helpers Padrino::Mailer::Helpers
        unless app.respond_to?(:mailer)
          app.send(:extend, Padrino::Mailer::Helpers::ClassMethods)
        end
      end
      alias :included :registered
    end
  end
end
