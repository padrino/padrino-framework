module Padrino
  module Cache
    ##
    # Defines a padrino parser for our cache store.
    #
    module Parser
      ##
      # With Parser::Plain we will store
      # text and object in a text format.
      #
      module Plain
        def self.decode(code)
          code.to_s
        end

        def self.encode(code)
          code.to_s
        end
      end

      ##
      # With Parser::Marshal we will store
      # text and object in a marshaled format.
      #
      module Marshal
        def self.decode(code)
          ::Marshal.load(code.to_s)
        end

        def self.encode(code)
          ::Marshal.dump(code)
        end
      end
    end
  end
end
