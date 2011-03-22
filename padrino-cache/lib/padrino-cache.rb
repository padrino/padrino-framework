require 'fileutils'
require 'padrino-core'
require 'padrino-helpers'
FileSet.glob_require('padrino-cache/{helpers}/*.rb', __FILE__)

module Padrino
  ##
  # This component enables caching of an application's response contents on
  # both page- and fragment-levels. Output cached in this manner is
  # persisted, until it expires or is actively expired, in a configurable store
  # of your choosing. Several common caching stores are supported out of the box.
  #
  module Cache
    autoload :Store, 'padrino-cache/store'

    class << self
      ##
      # Register these helpers:
      #
      #   Padrino::Cache::Helpers::CacheStore
      #   Padrino::Cache::FragmentHelpers
      #   Padrino::Cache::PageHelpers
      #
      # for Padrino::Application and set
      #
      #   set :cache_store, Padrino::Cache::Store::File.new(File.join(app.root, 'tmp', 'cache'))
      #
      def registered(app)
        app.helpers Padrino::Cache::Helpers::CacheStore
        app.helpers Padrino::Cache::Helpers::Fragment
        app.helpers Padrino::Cache::Helpers::Page
        app.set :cache_store, Padrino::Cache::Store::File.new(File.join(app.root, 'tmp', 'cache'))
        app.disable :caching
      end
      alias :included :registered

      def padrino_route_added(route, verb, path, args, options, block) #:nodoc
        Padrino::Cache::Helpers::Page.padrino_route_added(route, verb, path, args, options, block)
      end
    end
  end # Cache
end # Padrino