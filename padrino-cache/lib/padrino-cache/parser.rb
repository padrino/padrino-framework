module Padrino
  module Cache

    ##
    # Define a padrino parser for our cache
    #
    module Parser
      extend self

      def set(mod)
        raise "#{mod} should respond to encode" unless mod.method_defined?(:encode)
        raise "#{mod} should respond to decode" unless mod.method_defined?(:decode)
        @_parser = mod
      end

      def decode(code)
        @_parser.decode(code)
      end

      def encode(code)
        @_parser.encode(code)
      end

      ##
      # With Parser::Plain we will store
      # text and object in a text format
      #
      module Plain
        def decode(code)
          code
        end

        def encode(code)
          code
        end
      end

      module Marshal
        def decode(code)
          Marshal.load(code)
        end

        def encode(code)
          Marshal.dump(code)
        end
      end

      # Let's set Plain as default encoder
      set Plain
    end # Parser
  end # Cache
end # Padrino
