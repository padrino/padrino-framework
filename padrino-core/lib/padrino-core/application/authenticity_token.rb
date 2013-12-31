module Padrino
  class AuthenticityToken < Rack::Protection::AuthenticityToken
    def initialize(app, options = {})
      @app    = app
      @except = options.delete(:except) if options.has_key?(:except)
      super
    end

    def call(env)
      if @except && @except.call(env)
        @app.call(env)
      else
        super(env)
      end
    end
  end
end

