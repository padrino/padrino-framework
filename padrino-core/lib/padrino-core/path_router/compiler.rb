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
          route.regexp = /\A(?:#{route.matcher.to_regexp})\z/
        end
        index_by_prefix!
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

      ##
      # Finds the first route that matches PATH_INFO, and returns it with its params, read from
      # the path as the route matched it. Returns nil when no route matches.
      #
      def recognize_path(path_info)
        compile! unless compiled?
        pattern = decode_pattern(path_info)
        route = match?(0, pattern)
        [route, route.params_for(pattern, {})] if route
      end

      private

      ##
      # Returns a instance of PathRouter::Route if path is matched with current regexp
      #
      def match?(offset, path)
        return unless path

        trimmed = path[0..-2] if path.end_with?('/')
        routes = @routes
        # The index holds positions in routes as they were compiled, so it is used only while
        # routes still holds the same routes in the same order. After any other edit to routes,
        # match? looks through them one by one.
        if (prefix_index = @prefix_index) && path.length >= PREFIX_SIZE && routes == prefix_index[2]
          by_prefix, unprefixed, = prefix_index
          candidates = by_prefix.fetch(path[0, PREFIX_SIZE], unprefixed)
          from = candidates.bsearch_index { |index| index >= offset }
          return unless from

          from.upto(candidates.size - 1) do |at|
            route = routes[candidates[at]]
            regexp = route.regexp
            return route if regexp.match?(path) || (trimmed && regexp.match?(trimmed))
          rescue Encoding::CompatibilityError
            # A Regexp fixed to another encoding (/n with non-ASCII bytes) matches no path it can't
            # read, as in Sinatra (see Routing.path_match?). The same holds in the loop below.
          end
          return
        end
        while (route = routes[offset])
          regexp = route.regexp
          begin
            # A route added after compiling has no regexp and matches nothing.
            return route if regexp && (regexp.match?(path) || (trimmed && regexp.match?(trimmed)))
          rescue Encoding::CompatibilityError
            nil
          end
          offset += 1
        end
      end

      # How many leading characters of a path pick the routes to try (index_by_prefix!).
      PREFIX_SIZE = 3
      # The start of a Sinatra pattern that can only match itself: plain characters, up to the
      # first one that may be special (':', '*', '(', '?', '{', '\\', '+' ...).
      LITERAL_START = %r{\A[A-Za-z0-9_\-/.~]*}

      ##
      # Sorts the routes by the first PREFIX_SIZE characters a path they match must start with,
      # so that match? only tries the routes that can match it. A route whose pattern doesn't
      # fix that many (a Regexp, a capture or group early, an optional character, a '|') is tried
      # for every path.
      #
      def index_by_prefix!
        prefixed = Hash.new { |hash, key| hash[key] = [] }
        unprefixed = []
        @routes.each_with_index do |route, index|
          (prefix = literal_prefix(route)) ? prefixed[prefix] << index : unprefixed << index
        end
        by_prefix = prefixed.transform_values { |indexes| (indexes + unprefixed).sort.freeze }.freeze
        # One frozen value, set in one assignment: match? reads it once, so a thread matching while
        # another compiles the same engine sees the lists and routes from the same compile.
        @prefix_index = [by_prefix, unprefixed.freeze, @routes.dup.freeze].freeze
      end

      # The first PREFIX_SIZE characters every path the route matches starts with, or nil.
      def literal_prefix(route)
        path = route.original_path
        return unless path.is_a?(String) && !path.include?('|')

        literal = path[LITERAL_START]
        literal = literal[0..-2] if path[literal.length] == '?'
        literal[0, PREFIX_SIZE] if literal.length >= PREFIX_SIZE
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
      # A path that decodes to a newline, as routes see it or as route params decode it again
      # (a '%0A' left by '%250A'), matches no route either.
      #
      def decode_pattern(pattern)
        # Without an escape, decoding an ASCII path only changes its encoding.
        if pattern.ascii_only? && !pattern.include?('%') && Encoding.default_external.ascii_compatible?
          return pattern.include?("\n") ? nil : pattern.dup.force_encoding(Encoding::UTF_8)
        end

        pattern = pattern.encode(Encoding.default_external)
        return if pattern.match?(/%(?!\h\h)/)

        decoded = Padrino::Routing.decode_route_path(pattern)
        decoded if decoded.valid_encoding? && !decoded.match?(/\n|%0a/i)
      rescue ArgumentError, EncodingError
        nil
      end
    end
  end
end
