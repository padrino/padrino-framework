require 'fileutils' unless defined?(FileUtils)
require 'padrino-core'
require 'padrino-helpers'
FileSet.glob_require('padrino-cache/{helpers}/*.rb', __FILE__)
require 'moneta'

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
    #   Padrino.cache = Padrino::Cache.new(:LRUHash) # default choice
    #   Padrino.cache = Padrino::Cache.new(:File, :dir => Padrino.root('tmp', app_name.to_s, 'cache')) # Keeps cached values in file
    #   Padrino.cache = Padrino::Cache.new(:Memcached) # Uses default server at localhost
    #   Padrino.cache = Padrino::Cache.new(:Memcached, :server => '127.0.0.1:11211', :exception_retry_limit => 1)
    #   Padrino.cache = Padrino::Cache.new(:Memcached, :backend => memcached_or_dalli_instance)
    #   Padrino.cache = Padrino::Cache.new(:Redis) # Uses default server at localhost
    #   Padrino.cache = Padrino::Cache.new(:Redis, :host => '127.0.0.1', :port => 6379, :db => 0)
    #   Padrino.cache = Padrino::Cache.new(:Redis, :backend => redis_instance)
    #   Padrino.cache = Padrino::Cache.new(:Mongo) # Uses default server at localhost
    #   Padrino.cache = Padrino::Cache.new(:Mongo, :backend => mongo_client_instance)
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
      #   Padrino::Cache::Helpers::ObjectCache
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
      #   set :cache, Padrino::Cache.new(:LRUHash) # Keeps cached values in memory
      #   set :cache, Padrino::Cache.new(:Memcached) # Uses default server at localhost
      #   set :cache, Padrino::Cache.new(:Memcached, '127.0.0.1:11211', :exception_retry_limit => 1)
      #   set :cache, Padrino::Cache.new(:Memcached, :backend => memcached_or_dalli_instance)
      #   set :cache, Padrino::Cache.new(:Redis) # Uses default server at localhost
      #   set :cache, Padrino::Cache.new(:Redis, :host => '127.0.0.1', :port => 6379, :db => 0)
      #   set :cache, Padrino::Cache.new(:Redis, :backend => redis_instance)
      #   set :cache, Padrino::Cache.new(:Mongo) # Uses default server at localhost
      #   set :cache, Padrino::Cache.new(:Mongo, :backend => mongo_client_instance)
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
        app.helpers Padrino::Cache::Helpers::ObjectCache
        app.helpers Padrino::Cache::Helpers::CacheStore
        app.helpers Padrino::Cache::Helpers::Fragment
        app.helpers Padrino::Cache::Helpers::Page
        unless app.respond_to?(:cache)
          cache_dir = Padrino.root('tmp', defined?(app.app_name) ? app.app_name.to_s : '', 'cache')
          app.set :cache, Padrino::Cache.new(:File, :dir => cache_dir)
        end
        app.disable :caching unless app.respond_to?(:caching)
        included(app)
      end

      def included(base)
        base.extend Padrino::Cache::Helpers::Page::ClassMethods
      end

      def padrino_route_added(route, verb, path, args, options, block)
        Padrino::Cache::Helpers::Page.padrino_route_added(route, verb, path, args, options, block)
      end
    end

    def self.new(name, options = {})
      # Activate expiration by default
      options[:expires] = true unless options.include?(:expires)
      Moneta.new(name, options)
    end

    Padrino.cache = Padrino::Cache.new(:LRUHash)
  end
end
