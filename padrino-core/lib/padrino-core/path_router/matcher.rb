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
        params = params.dup
        query = params.keys.each_with_object({}) do |key, result|
          result[key] = params.delete(key) unless handler.names.include?(key.to_s)
        end
        params.merge!(@default_values) if @default_values.is_a?(Hash)
        expanded_path = handler.expand(params)
        expanded_path += "?" + query.to_query unless query.empty?
        expanded_path
      end
  
      ##
      # Returns true if handler is an instance of Mustermann.
      #
      def mustermann?
        handler.instance_of?(Mustermann::Sinatra)
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
    end
  end
end
