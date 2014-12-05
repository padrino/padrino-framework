require 'mustermann/sinatra'

module Padrino
  module PathRouter
    class Matcher
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
        pattern = pattern[0..-2] if mustermann? && pattern != "/" && pattern.end_with?("/")
        handler.match(pattern)
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
        params = params.merge(@default_values) if @default_values.is_a?(Hash)
        expanded_path = handler.expand(:append, params)
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
            Mustermann.new(@path, :capture => @capture)
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
