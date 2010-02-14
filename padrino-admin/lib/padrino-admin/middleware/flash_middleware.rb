require 'rack/utils'

module Padrino
  module Admin
    module Middleware
      ##
      # FlashMiddleware help you passing your session in the URI, when it should be in the cookie.
      # 
      # This code it's only performed when:
      # 
      #   env['HTTP_USER_AGENT'] =~ /^(Adobe|Shockwave) Flash/
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