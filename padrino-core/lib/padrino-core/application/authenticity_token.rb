module Padrino
  class AuthenticityToken < Rack::Protection::AuthenticityToken
    def initialize(app, options = {})
      @app = app
      @except = options[:except]
      @except = Array(@except) unless @except.is_a?(Proc)
      super
    end

    def call(env)
      if except?(env)
        @app.call(env)
      else
        super
      end
    end

    def except?(env)
      return false unless @except
      return @except.call(env) if @except.is_a?(Proc)

      path_info = env['PATH_INFO']
      @except.any? { |path| path.is_a?(Regexp) ? path.match(path_info) : path == path_info }
    end
  end
end
