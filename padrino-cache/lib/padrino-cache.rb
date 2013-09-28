require 'fileutils' unless defined?(FileUtils)
require 'padrino-core'
require 'padrino-helpers'
FileSet.glob_require('padrino-cache/{helpers}/*.rb', __FILE__)
require 'moneta'
require 'padrino-cache/legacy_store'

module Padrino
  class << self
    ##
    # Returns the caching engine.
    #
    # @example
    #   # with: Padrino.cache = Padrino::Cache.new(:File, :dir => /my/cache/path)
    #   Padrino.cache['val'] = 'test'
    #   Padrino.cache['val'] # => 'test'
    #   Padrino.cache.delete('val')
    #   Padrino.cache.clear
    #
    def cache
      @_cache
    end

    ##
    # Set the caching engine.
    #
    # @param value
    #   Instance of Moneta store
    #
    # @example
    #   Padrino.cache = Padrino::Cache.new(:LRUHash)
    #   Padrino.cache = Padrino::Cache.new(:Memcached)
    #   Padrino.cache = Padrino::Cache.new(:Redis)
    #   Padrino.cache = Padrino::Cache.new(:File, :dir => Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
    #
    #   # You can manage your cache from anywhere in your app:
    #
    #   Padrino.cache['val'] = 'test'
    #   Padrino.cache['val'] # => 'test'
    #   Padrino.cache.delete('val')
    #   Padrino.cache.clear
    #
    def cache=(value)
      @_cache= value
    end
  end

  ##
  # This component enables caching of an application's response contents on
  # both page- and fragment-levels. Output cached in this manner is
  # persisted, until it expires or is actively expired, in a configurable store
  # of your choosing. Several common caching stores are supported out of the box.
  #
  module Cache
    class << self
      ##
      # Register these helpers:
      #
      #   Padrino::Cache::Helpers::CacheStore
      #   Padrino::Cache::Helpers::Fragment
      #   Padrino::Cache::Helpers::Page
      #
      # for Padrino::Application.
      #
      # By default we use FileStore as showed below:
      #
      #   set :cache, Padrino::Cache.new(:File, :dir => Padrino.root('tmp', app_name.to_s, 'cache'))
      #
      # However, you can also change the file store easily in your app.rb:
      #
      #   set :cache, Padrino::Cache.new(:LRUHash)
      #   set :cache, Padrino::Cache.new(:Memcached)
      #   set :cache, Padrino::Cache.new(:Redis)
      #   set :cache, Padrino::Cache.new(:File, :dir => Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
      #
      # You can manage your cache from anywhere in your app:
      #
      #   MyApp.cache['val'] = 'test'
      #   MyApp.cache['val'] # => 'test'
      #   MyApp.cache.delete('val')
      #   MyApp.cache.clear
      #
      def registered(app)
        app.helpers Padrino::Cache::Helpers::CacheStore
        app.helpers Padrino::Cache::Helpers::Fragment
        app.helpers Padrino::Cache::Helpers::Page
        app.set :cache, Padrino::Cache.new(:File,
                                           :dir => Padrino.root('tmp', defined?(app.app_name) ? app.app_name.to_s : '', 'cache'))
        app.disable :caching
      end
      alias :included :registered

      def padrino_route_added(route, verb, path, args, options, block)
        Padrino::Cache::Helpers::Page.padrino_route_added(route, verb, path, args, options, block)
      end
    end

    def self.new(name, options = {})
      # Activate expiration by default
      options[:expires] = true unless options.include?(:expires)
      a = Moneta.new(name, options)
      Moneta.build do
        # Use proxy to support deprecated Padrino interface
        use LegacyStore
        adapter a
      end
    end

    Padrino.cache = Padrino::Cache.new(:LRUHash)
  end
end
