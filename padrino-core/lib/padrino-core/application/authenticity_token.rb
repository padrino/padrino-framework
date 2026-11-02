module Padrino
  class AuthenticityToken < Rack::Protection::AuthenticityToken
    # A path with more dots than this isn't exempted by a Regexp: each dot adds forms to compare.
    MAX_DOTS = 16

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

      # A request is excepted only if every form of the path that can reach a route is. This
      # middleware has no route to ask for a format, so the forms without one count too, unless
      # String entries name the path as it is. A path with a newline is never excepted.
      forms = Routing.path_forms(env['PATH_INFO'].to_s)
      return false if forms.any? { |form| form.include?("\n") }
      return true if forms.all? { |form| @except.include?(form) }
      return false if forms.any? { |form| form.count('.') > MAX_DOTS }

      Routing.served_forms(forms).all? { |form| excepted?(form) }
    end

    private

    def excepted?(form)
      @except.any? { |path| path.is_a?(Regexp) ? path.match?(form) : path == form }
    end
  end
end
