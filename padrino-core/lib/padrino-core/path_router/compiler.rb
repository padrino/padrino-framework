module Padrino
  module PathRouter
    class Compiler
      attr_reader :regexps

      def initialize(routes)
        @routes = routes
      end
  
      def call(request)
        compile! unless compiled?
        pattern, verb, params = parse_request(request)
        candidacies = match_with(pattern)
        raise_exception(404) if candidacies.empty?
        candidacies, allows = candidacies.partition{|route| route.verb == verb }
        raise_exception(405, verbs: allows.map(&:verb)) if candidacies.empty?
        candidacies.map{|route| [route, route.params_for(pattern, params)]}
      end

      def compile!
        return if compiled?
        @regexps = @routes.map.with_index do |route, index|
          regexp = route.matcher.handler
          regexp = regexp.to_regexp if route.matcher.mustermann?
          route.index = index
          /(?<_#{index}>#{regexp})/
        end
        @regexps = compile(@regexps)
        @compiled = true
      end

      def compiled?
        !!@compiled
      end
  
      private

      def compile(regexps, paths = [])
        return paths if regexps.length.zero?
        paths << Regexp.union(regexps)
        regexps.shift
        compile(regexps, paths)
      end
  
      def match_with(pattern)
        offset = 0
        conditions = [pattern]
        conditions << pattern[0..-2] if pattern != "/" && pattern.end_with?("/")
        loop.with_object([]) do |_, candidacies|
          return candidacies unless conditions.any?{|x| @regexps[offset] === x }
          route = @routes[offset..-1].detect{|route| Regexp.last_match("_#{route.index}") }
          candidacies << route
          offset = route.index + 1
        end
      end
  
      def parse_request(request)
        if request.is_a?(Hash)
          [request['PATH_INFO'], request['REQUEST_METHOD'].downcase.to_sym, {}]
        else
          [request.path_info, request.request_method.downcase.to_sym, request.params]
        end
      end
  
      def raise_exception(error_code, options = {})
        raise ->(error_code) {
          case error_code
          when 400
            BadRequest
          when 404
            NotFound
          when 405
            MethodNotAllowed.new(options[:verbs])
          end
        }.call(error_code)
      end
    end
  end
end
