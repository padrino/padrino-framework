require 'mustermann/sinatra'

module Padrino
  module PathRouter
    class Matcher
      # To count group of regexp
      GROUP_REGEXP = %r{\((?!\?:|\?!|\?<=|\?<!|\?=).+?\)}.freeze

      ##
      # Constructs an instance of PathRouter::Matcher.
      #
      def initialize(path, options = {})
        @path = path.is_a?(String) && path.empty? ? "/" : path
        @capture = options[:capture]
        @default_values = options[:default_values]
      end

      ##
      # Matches a pattern with the route matcher.
      #
      def match(pattern)
        if match_data = handler.match(pattern)
          match_data
        elsif pattern != "/" && pattern.end_with?("/")
          handler.match(pattern[0..-2])
        end
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
          parts[handler.names.include?(key.to_s) ? 0 : 1][key] = val
        end
        expanded_path = handler.expand(:append, params)
        expanded_path += ?? + Padrino::Utils.build_uri_query(query) unless query.empty?
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
          params.merge!(:captures => data.captures) unless data.captures.empty?
        else
          if mustermann?
            new_params = handler.params(pattern, :captures => data)
            params.merge!(new_params) if new_params
          elsif data
            params.merge!(Hash[names.zip(data.captures)])
          end
          params.merge!(others){ |_, old, new| old || new }
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
            Mustermann.new(@path, :capture => @capture, :uri_decode => false)
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
        handler.names
      end

      ##
      # Returns captures parameter length.
      #
      def capture_length
        if mustermann?
          handler.named_captures.inject(0) { |count, (_, capture)| count += capture.length }
        else
          handler.inspect.scan(GROUP_REGEXP).length
        end
      end

      private

      ##
      # Creates a hash with indifferent access.
      #
      def indifferent_hash
        Hash.new{ |hash, key| hash[key.to_s] if key.instance_of?(Symbol) }
      end
    end
  end
end
