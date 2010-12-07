require 'fileutils'
require 'padrino-core'
require 'padrino-helpers'
FileSet.glob_require('padrino-cache/{helpers}/*.rb', __FILE__)

module Padrino
  module Cache
    ##
    # Register these helpers:
    #
    #   Padrino::Cache::FragmentHelpers
    #   Padrino::Cache::PageHelpers
    #
    # for Padrino::Application
    #

    autoload :Store, 'padrino-cache/store'

    class << self
      def registered(app)
        app.helpers Padrino::Cache::Helpers::CacheStore
        app.helpers Padrino::Cache::Helpers::Fragment
        app.helpers Padrino::Cache::Helpers::Page
        app.set :cache_store, Padrino::Cache::Store::File.new(File.join(app.root, 'tmp', 'cache'))
        app.disable :caching
      end
      alias :included :registered

      def padrino_route_added(route, verb, path, args, options, block)
        Padrino::Cache::Helpers::Page.padrino_route_added(route, verb, path, args, options, block)
      end
    end
  end # Helpers
end # Padrino