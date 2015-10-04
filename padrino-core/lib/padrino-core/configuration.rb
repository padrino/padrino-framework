require 'ostruct'

module Padrino
  ##
  # Padrino simple configuration module
  #
  module Configuration
    ##
    # Returns the configuration structure allowing to get and set it's values.
    # Padrino.config is a simple Ruby OpenStruct object with no additional magic.
    #
    # Example:
    #
    #   Padrino.config.value1 = 42
    #   exit if Padrino.config.exiting
    #
    def config
      @config ||= OpenStruct.new
    end

    ##
    # Allows to configure different environments differently. Requires a block.
    #
    # Example:
    #
    #   Padrino.configure :development do |config|
    #     config.value2 = 'only development'
    #   end
    #   Padrino.configure :development, :production do |config|
    #     config.value2 = 'both development and production'
    #   end
    #   Padrino.configure do |config|
    #     config.value2 = 'any environment'
    #   end
    #
    def configure(*environments)
      yield(config) if environments.empty? || environments.include?(Padrino.env)
    end
  end
end
