require 'rack/utils'

module Padrino
  module Admin
    module Middleware
      ##
      # FlashSessionCookieMiddleware
      #   passing your session in the URI, when it should be in the cookie
      #
      # This code only works in following cases:
      # - passing the session as the variable for 'session_key' (it is best to set this to your app's session cookie name
      # - the value is URI escaped once, (don't do it explicetally if using rails helpers, they do it for you)
      # - Loading this middleware before session_store middleware
      #
      # Note, this could work also after session_store middleware (or others).
      # However, these could already have modified the cooky values, and this module
      # could become unstable because of that, and it's functioning can not be
      # guaranteed.
      # 
      class FlashMiddleware
        def initialize(app, session_key = 'session_id')
          @app = app
          @session_key = session_key.to_s
        end

        def call(env)
          if env['HTTP_USER_AGENT'] =~ /^(Adobe|Shockwave) Flash/
            params = ::Rack::Request.new(env).params
            env['rack.session'][@session_key.to_sym] = params[@session_key] unless params[@session_key].nil?
          end
          @app.call(env)
        end
      end
    end
  end
end