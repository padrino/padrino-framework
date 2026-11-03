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
        pattern = decode_pattern(request.path_info)
        verb    = request.request_method
        rotation { |offset| match?(offset, pattern) }.select { |route| route.verb == verb }
      end

      ##
      # Calls routes by using request.
      #
      def call_by_request(request)
        path_info = pattern = nil
        rotation do |offset|
          # A route's filters may change the path before passing; decode it again only then.
          unless path_info && path_info == request.path_info
            path_info = request.path_info.dup
            pattern = decode_pattern(path_info)
          end
          if (route = match?(offset, pattern))
            yield(route, route.params_for(pattern, request.params)) if route.verb == request.request_method
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
        return unless path

        trimmed = path[0..-2] if path.end_with?('/')
        routes = @routes
        while (route = routes[offset])
          regexp = route.regexp
          # A route added after compiling has no regexp and matches nothing.
          return route if regexp && (regexp.match?(path) || (trimmed && regexp.match?(trimmed)))
          offset += 1
        end
      end

      ##
      # Runs through all regexps to find routes.
      #
      def rotation(offset = 0)
        compile! unless compiled?
        candidacies = []
        while (route = yield(offset))
          candidacies << route
          offset = route.index.next
        end
        candidacies
      end

      ##
      # Decode env["PATH_INFO"]. Returns nil when the path doesn't decode to valid text
      # (a malformed or non-UTF-8 escape such as "/%ff"), so it matches no route.
      #
      def decode_pattern(pattern)
        # Without an escape, decoding an ASCII path only changes its encoding.
        if pattern.ascii_only? && !pattern.include?('%') && Encoding.default_external.ascii_compatible?
          return pattern.dup.force_encoding(Encoding::UTF_8)
        end

        decoded = decode_uri(encode_default_external(pattern))
        decoded if decoded.valid_encoding?
      rescue ArgumentError, EncodingError
        nil
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
        string.split(/%2F|%2f/, -1).map { |part| Rack::Utils.unescape(part.gsub('+', '%2B')) }.join('%2F')
      end
    end
  end
end
