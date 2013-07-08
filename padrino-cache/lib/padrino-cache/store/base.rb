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
          @never = -1
          self.parser = options[:parser] || :plain
        end

        private

        def get_expiry( opts )
          if opts && opts[:expires_in] && opts[:expires_in] != -1
            expires_in = opts[:expires_in].to_i
            expires_in = EXPIRES_EDGE  if expires_in > EXPIRES_EDGE
            Time.now.to_i + expires_in
          else
            @never
          end
        end

        def now_before?( expiry )
          expiry.to_i == @never || expiry.to_i > Time.now.to_i
        end
      end # Base
    end # Store
  end # Cache
end # Padrino

