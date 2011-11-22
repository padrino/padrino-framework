require 'fileutils'
require 'padrino-helpers'
require 'padrino-cache'
FileSet.glob_require('padrino-cache-helpers/*.rb', __FILE__)

module Padrino
  module Cache
    module Helpers
      class << self
        ##
        # Register these helpers:
        #   Padrino::Cache::Helpers::CacheStore
        #   Padrino::Cache::Helpers::Fragment
        #   Padrino::Cache::Helpers::Page
        #
        # for Padrino::Application.
        #
        # @api public
        def registered(app)
          app.register Padrino::Cache
          app.helpers Padrino::Cache::Helpers::CacheStore
          app.helpers Padrino::Cache::Helpers::Fragment
          app.helpers Padrino::Cache::Helpers::Page
        end
        alias :included :registered

        # @private
        def padrino_route_added(route, verb, path, args, options, block) # @private
          Padrino::Cache::Helpers::Page.padrino_route_added(route, verb, path, args, options, block)
        end
      end 
    end # Helpers
  end # Cache
end # Padrino
