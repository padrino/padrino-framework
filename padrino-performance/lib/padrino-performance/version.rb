module Padrino
  module Performance
    # The version constant for the current version of Padrino.
    VERSION = '0.11.3' unless defined?(Padrino::VERSION)

    #
    # The current Padrino version.
    #
    # @return [String]
    #   The version number.
    #
    def self.version
      VERSION
    end
  end
end
