require 'mustermann/sinatra'

module Padrino
  module PathRouter
    class Matcher
      # To count group of regexp
      GROUP_REGEXP = /\((?!\?:|\?!|\?<=|\?<!|\?=).+?\)/
      # Most key lists a matcher remembers for expand_path.
      MAX_EXACT_KEYS = 32

      ##
      # Constructs an instance of PathRouter::Matcher.
      #
      def initialize(path, options = {})
        @path = path.is_a?(String) && path.empty? ? '/' : path
        @capture = options[:capture]
        @default_values = options[:default_values]
      end

      ##
      # Matches a pattern with the route matcher.
      #
      def match(pattern)
        if (match_data = whole_regexp.match(pattern))
          match_data
        elsif pattern != '/' && pattern.end_with?('/')
          whole_regexp.match(pattern[0..-2])
        end
      rescue Encoding::CompatibilityError
        # A Regexp fixed to another encoding doesn't match (see Routing.path_match?).
        nil
      end

      # The handler, anchored to the whole path as PathRouter::Compiler matches routes
      # (Mustermann's \Z and a Regexp route's ^$ stop before a newline).
      def whole_regexp
        @whole_regexp ||= to_regexp.is_a?(Regexp) ? /\A(?:#{to_regexp})\z/ : handler
      end

      ##
      # Returns a regexp from handler.
      #
      def to_regexp
        mustermann? ? handler.to_regexp : handler
      end

      ##
      # Expands the path by using parameters.
      #
      def expand(params)
        params = @default_values.merge(params) if @default_values.is_a?(Hash)
        params, query = params.each_with_object([{}, {}]) do |(key, val), parts|
          if names.include?(key.to_s)
            # Mustermann escapes an Integer through a slow path; its digits need no escaping.
            parts[0][key] = val.instance_of?(Integer) ? val.to_s : val
          else
            parts[1][key] = val
          end
        end
        expanded_path = expand_path(params)
        expanded_path += "?#{Padrino::Utils.build_uri_query(query)}" unless query.empty?
        expanded_path
      end

      ##
      # Returns true if handler is an instance of Mustermann.
      #
      def mustermann?
        handler.instance_of?(Mustermann::Sinatra)
      end

      ##
      # Builds a parameters, and returns them.
      #
      def params_for(pattern, others)
        data = match(pattern)
        params = indifferent_hash
        if data.names.empty?
          params.merge!(captures: data.captures) unless data.captures.empty?
        else
          if mustermann?
            new_params = handler.params(pattern, captures: data)
            params.merge!(new_params) if new_params
          elsif data
            params.merge!(Hash[names.zip(data.captures)])
          end
          params.merge!(others) { |_, old, new| old || new }
        end
        params
      end

      ##
      # Returns the handler which is an instance of Mustermann or Regexp.
      #
      def handler
        @handler ||=
          case @path
          when String
            Mustermann.new(@path, capture: @capture, uri_decode: false)
          when Regexp
            /^(?:#{@path})$/
          else
            @path
          end
      end

      ##
      # Converts the handler into string.
      #
      def to_s
        handler.to_s
      end

      ##
      # Returns names of the handler.
      # @see Regexp#names
      #
      def names
        @names ||= handler.names.dup.freeze
      end

      ##
      # Returns captures parameter length.
      #
      def capture_length
        if mustermann?
          handler.named_captures.inject(0) { |count, (_, capture)| count + capture.length }
        else
          handler.inspect.scan(GROUP_REGEXP).length
        end
      end

      private

      ##
      # Mustermann's expand(:append, params). When the params fill one of the
      # pattern's forms exactly, :append has nothing to append, and expand(:raise)
      # gives the same path faster. Whether they do depends only on the keys,
      # so it is found out once per list of keys, for params whose values are
      # all Strings or Symbols (Integers arrive as Strings). Any other value
      # (nil, an Array, an object) goes through :append and leaves the memo alone.
      #
      def expand_path(params)
        return handler.expand(:append, params) unless params.all? { |_, value| value.instance_of?(String) || value.instance_of?(Symbol) }

        keys = params.keys
        exact = (@exact_keys ||= {}.freeze)[keys]
        return handler.expand(:raise, params) if exact

        path = handler.expand(:append, params)
        if exact.nil? && @exact_keys.size < MAX_EXACT_KEYS
          exact = begin
            handler.expand(:raise, params) == path
          rescue Mustermann::ExpandError, ArgumentError
            false
          end
          @exact_keys = @exact_keys.merge(keys.freeze => exact).freeze
        end
        path
      end

      ##
      # Creates a hash with indifferent access.
      #
      def indifferent_hash
        Hash.new { |hash, key| hash[key.to_s] if key.instance_of?(Symbol) }
      end
    end
  end
end
