module Padrino
  module Cache
    module Store
      ##
      # Memcache Cache Store
      #
      class Memcache < Base
        ##
        # Initialize Memcache store with client connection.
        #
        # @param client
        #   instance of Memcache library
        #
        # @example
        #   Padrino.cache = Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211'))
        #   Padrino.cache = Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
        #   # or from your app
        #   set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211'))
        #   set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
        #
        def initialize(client, options={})
          @backend = client
          super(options)
          @never = 0  # never TTL in Memcache is 0
        end

        ##
        # Return the value for the given key.
        #
        # @param [String] key
        #   cache key to retrieve value
        #
        # @example
        #   MyApp.cache.get('records')
        #
        def get(key)
          @backend.get(key)
        rescue Memcached::NotFound
          nil
        end

        ##
        # Set the value for a given key and optionally with an expire time.
        # Default expiry time is 86400.
        #
        # @param [String] key
        #   cache key
        # @param value
        #   value of cache key
        #
        # @example
        #   MyApp.cache.set('records', records)
        #   MyApp.cache.set('records', records, :expires_in => 30) # => 30 seconds
        #
        def set(key, value, opts = nil)
          @backend.set(key, value, get_expiry(opts))
        end

        ##
        # Delete the value for a given key.
        #
        # @param [String] key
        #   cache key
        #
        # @example
        #   MyApp.cache.delete('records')
        #
        def delete(key)
          @backend.delete(key)
        end

        ##
        # Reinitialize your cache.
        #
        # @example
        #   MyApp.cache.flush
        #   MyApp.cache.get('records') # => nil
        #
        def flush
          @backend.respond_to?(:flush_all) ? @backend.flush_all : @backend.flush
        end
      end
    end
  end
end
