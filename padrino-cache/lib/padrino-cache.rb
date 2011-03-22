require 'fileutils'
require 'padrino-core'
require 'padrino-helpers'
FileSet.glob_require('padrino-cache/{helpers}/*.rb', __FILE__)

module Padrino
  class << self
    ##
    # Returns the caching engine
    #
    # ==== Examples
    #   # with: Padrino.cache = Padrino::Cache::Store::File.new(/my/cache/path)
    #   Padrino.cache.set('val', 'test')
    #   Padrino.cache.get('val') # => 'test'
    #   Padrino.cache.delete('val')
    #   Padrino.cache.flush
    #
    def cache
      @_cache
    end

    ##
    # Set the caching engine
    #
    # === Examples
    #   Padrino.cache = Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
    #   Padrino.cache = Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
    #   Padrino.cache = Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
    #   Padrino.cache = Padrino::Cache::Store::Memory.new(50)
    #   Padrino.cache = Padrino::Cache::Store::File.new(/my/cache/path)
    #
    def cache=(value)
      @_cache = value
    end
  end # self

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
      # for Padrino::Application.
      #
      # By default we use FileStore as showed below:
      #
      #   set :cache, Padrino::Cache::Store::File.new(File.join(app.root, 'tmp', 'cache'))
      #
      # Remember that for each app you can change this value:
      #
      #   set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
      #   set :cache, Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
      #   set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
      #   set :cache, Padrino::Cache::Store::Memory.new(50)
      #
      # Every where from your app you can manage your cache:
      #
      #   MyApp.cache.set('val', 'test')
      #   MyApp.cache.get('val') # => 'test'
      #   MyApp.cache.delete('val')
      #   MyApp.cache.flush
      #
      def registered(app)
        app.helpers Padrino::Cache::Helpers::CacheStore
        app.helpers Padrino::Cache::Helpers::Fragment
        app.helpers Padrino::Cache::Helpers::Page
        app.set :cache, Padrino::Cache::Store::File.new(File.join(app.root, 'tmp', 'cache'))
        app.disable :caching
      end
      alias :included :registered

      def padrino_route_added(route, verb, path, args, options, block) #:nodoc
        Padrino::Cache::Helpers::Page.padrino_route_added(route, verb, path, args, options, block)
      end
    end
  end # Cache
end # Padrino