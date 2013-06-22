module Padrino
  module Cache
    module Store
      ##
      # Abstract Cache Store
      #
      class Base

        ##
        # Get the cache parser strategy
        #
        # By default is plain, otherwise you can set **Marshal** or write your own.
        #
        def parser
          @_parser
        end

        ##
        # Set the caching parser strategy
        #
        # @param value
        #   Module of Padrino::Cache::Parser or any that respond to encode/decode
        #
        # @example
        #   Padrino.cache.parser = :plain
        #   Padrino.cache.parser = :marshal
        #   # shortcuts for:
        #   Padrino.cache.parser = Padrino::Cache::Parser::Plain
        #   Padrino.cache.parser = Padrino::Cache::Parser::Marshal
        #
        # You can easily write your own:
        #
        # @example
        #   require 'oj'
        #   module FastJSONParser
        #     def self.encode(value)
        #       OJ.dump(value)
        #     end
        #
        #     def self.decode(value)
        #       Oj.load(value)
        #     end
        #   end
        #
        #   Padrino.cache_parser = FastJSONParser
        #
        def parser=(mod)
          mod = Padrino::Cache::Parser.const_get(mod.to_s.camelize) unless mod.is_a?(Module)
          raise "#{mod} should respond to encode" unless mod.respond_to?(:encode)
          raise "#{mod} should respond to decode" unless mod.respond_to?(:decode)
          @_parser=mod
        end

        # @private
        def initialize(options={})
          self.parser = options[:parser] || :plain
        end

      end # Base
    end # Store
  end # Cache
end # Padrino

