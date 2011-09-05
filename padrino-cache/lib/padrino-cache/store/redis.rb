module Padrino
  module Cache
    module Store
      ##
      # Redis Cache Store
      #
      class Redis
        ##
        # Initialize Redis store with client connection.
        #
        # @param client
        #   Instance of Redis client
        #
        # @example
        #   Padrino.cache = Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
        #   # or from your app
        #   set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
        #
        # @api public
        def initialize(client)
          @backend = client
        end

        ##
        # Return the a value for the given key
        #
        # @param [String] key
        #   cache key
        #
        # @example
        #   # with MyApp.cache.set('records', records)
        #   MyApp.cache.get('records')
        #
        # @api public
        def get(key)
          code = @backend.get(key)
          Marshal.load(code) if code.present?
        end

        ##
        # Set the value for a given key and optionally with an expire time
        # Default expiry is 86400.
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
        # @api public
        def set(key, value, opts = nil)
          value = Marshal.dump(value) if value
          if opts && opts[:expires_in]
            expires_in = opts[:expires_in].to_i
            expires_in = expires_in if expires_in < EXPIRES_EDGE
            @backend.setex(key, expires_in, value)
          else
            @backend.set(key, value)
          end
        end

        ##
        # Delete the value for a given key
        #
        # @param [String] key
        #   cache key
        #
        # @example
        #   # with: MyApp.cache.set('records', records)
        #   MyApp.cache.delete('records')
        #
        # @api public
        def delete(key)
          @backend.del(key)
        end

        ##
        # Reinitialize your cache
        #
        # @example
        #   # with: MyApp.cache.set('records', records)
        #   MyApp.cache.flush
        #   MyApp.cache.get('records') # => nil
        #
        # @api public
        def flush
          @backend.flushdb
        end
      end # Redis
    end # Store
  end # Cache
end # Padrino
