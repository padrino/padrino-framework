module Padrino
  module PathRouter
    #
    # High performance engine for finding all routes which are matched with pattern
    #
    class Compiler
      attr_accessor :routes

      ##
      # Constructs an instance of Padrino::PathRouter::Compiler
      #
      def initialize(routes)
        @routes = routes
      end
  
      ##
      # Compiles all routes into regexps.
      #
      def compile!
        return if compiled?
        @routes.each_with_index do |route, index|
          route.index = index
          route.regexp = /(?<_#{index}>#{route.matcher.to_regexp})/
        end
        @compiled = true
      end

      ##
      # Returns true if all routes has been compiled.
      #
      def compiled?
        !!@compiled
      end

      ##
      # Finds routes by using request or env.
      #
      def find_by(request_or_env)
        request = request_or_env.is_a?(Hash) ? Sinatra::Request.new(request_or_env) : request_or_env
        pattern  = decode_pattern(request.path_info)
        verb    = request.request_method
        rotation { |offset| match?(offset, pattern) }.select { |route| route.verb == verb }
      end

      ##
      # Calls routes by using request.
      #
      def call_by_request(request)
        rotation do |offset|
          pattern  = decode_pattern(request.path_info)
          if route = match?(offset, pattern)
            params = route.params_for(pattern, request.params)
            yield(route, params) if route.verb == request.request_method
            route
          end
        end
      end

      ##
      # Finds routes by using PATH_INFO.
      #
      def find_by_pattern(pattern)
        pattern  = decode_pattern(pattern)
        rotation { |offset| match?(offset, pattern) }
      end
  
      private

      ##
      # Returns a instance of PathRouter::Route if path is matched with current regexp
      #
      def match?(offset, path)
        @routes[offset..-1].find do |route|
          route.regexp === path || (path.end_with?("/") && route.regexp === path[0..-2])
        end
      end

      ##
      # Runs through all regexps to find routes.
      #
      def rotation(offset = 0)
        compile! unless compiled?
        loop.with_object([]) do |_, candidacies|
          return candidacies unless route = yield(offset)
          candidacies << route
          offset = route.index.next
        end
      end

      ##
      # Decode env["PATH_INFO"]
      #
      def decode_pattern(pattern)
        decode_uri(encode_default_external(pattern))
      end

      ##
      # Encode string with Encoding.default_external
      #
      def encode_default_external(string)
        string.encode(Encoding.default_external)
      end

      ##
      # Decode uri escape sequences
      #
      def decode_uri(string)
        string.split(/%2F|%2f/, -1).map { |part| Rack::Utils.unescape(part) }.join('%2F')
      end
    end
  end
end
