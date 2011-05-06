module Padrino
  module Cache
    module Store
      ##
      # Memcache Cache Store
      #
      class Memcache
        ##
        # Initialize Memcache store with client connection.
        #
        # ==== Examples
        #   Padrino.cache = Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211'))
        #   Padrino.cache = Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
        #   # or from your app
        #   set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211'))
        #   set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
        #
        def initialize(client)
          @backend = client
        rescue
          raise
        end

        ##
        # Return the a value for the given key
        #
        # ==== Examples
        #   # with MyApp.cache.set('records', records)
        #   MyApp.cache.get('records')
        #
        def get(key)
          @backend.get(key)
        rescue Memcached::NotFound
          nil
        end

        ##
        # Set the value for a given key and optionally with an expire time
        # Default expiry time is 86400.
        #
        # ==== Examples
        #   MyApp.cache.set('records', records)
        #   MyApp.cache.set('records', records, :expires_in => 30) # => 30 seconds
        #
        def set(key, value, opts = nil)
          if opts && opts[:expires_in]
            expires_in = opts[:expires_in].to_i
            expires_in = (@backend.class.name == "MemCache" ? expires_in : Time.new.to_i + expires_in) if expires_in < EXPIRES_EDGE
            @backend.set(key, value, expires_in)
          else
            @backend.set(key, value)
          end
        end

        ##
        # Delete the value for a given key
        #
        # ==== Examples
        #   # with: MyApp.cache.set('records', records)
        #   MyApp.cache.delete('records')
        #
        def delete(key)
          @backend.delete(key)
        end

        ##
        # Reinitialize your cache
        #
        # ==== Examples
        #   # with: MyApp.cache.set('records', records)
        #   MyApp.cache.flush
        #   MyApp.cache.get('records') # => nil
        #
        def flush
          @backend.respond_to?(:flush_all) ? @backend.flush_all : @backend.flush
        end
      end # Memcached
    end # Store
  end # Cache
end # Padrino