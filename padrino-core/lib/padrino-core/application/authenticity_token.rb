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

      seen = {}
      forms.all? { |form| excepted_with_reductions?(form, seen) }
    end

    private

    def excepted_with_reductions?(form, seen)
      return true if seen[form]

      seen[form] = true
      excepted?(form) && reductions(form).all? { |size| excepted_with_reductions?(form[0, size], seen) }
    end

    def excepted?(form)
      @except.any? { |path| path.is_a?(Regexp) ? path.match?(form) : path == form }
    end

    # The sizes of what the router can take for the path of +form+: without its trailing slashes,
    # and up to each dot of its last segment, as a route can capture any of those suffixes.
    def reductions(form)
      sizes = []
      stripped = [Routing.strip_trailing(form).size, 1].max
      sizes << stripped if stripped < form.size
      offset = form.rindex('/').to_i
      while (offset = form.index('.', offset))
        sizes << offset
        offset += 1
      end
      sizes
    end
  end
end
