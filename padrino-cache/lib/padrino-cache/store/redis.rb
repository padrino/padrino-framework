module Padrino
  module Cache
    module Store
      ##
      # Redis Cache Store
      #
      class Redis < Base
        ##
        # Initialize Redis store with client connection.
        #
        # @param client
        #   Instance of Redis client.
        #
        # @example
        #   Padrino.cache = Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
        #   # or from your app
        #   set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
        #   # you can provide a marshal parser (to store ruby objects)
        #   set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0), :parser => :marshal)
        #
        def initialize(client, options={})
          @backend = client
          super(options)
        end

        ##
        # Return the value for the given key.
        #
        # @param [String] key
        #   cache key
        #
        # @example
        #   # with MyApp.cache.set('records', records)
        #   MyApp.cache.get('records')
        #
        def get(key)
          code = @backend.get(key)
          return nil unless code
          parser.decode(code)
        end

        ##
        # Set the value for a given key and optionally with an expire time.
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
        def set(key, value, opts = nil)
          value = parser.encode(value)
          if opts && opts[:expires_in] && opts[:expires_in] >= 0
            @backend.set(key, value)
            @backend.expireat(key, get_expiry(opts))
          else
            @backend.set(key, value)
          end
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
          @backend.del(key)
        end

        ##
        # Reinitialize your cache.
        #
        # @example
        #   MyApp.cache.flush
        #   MyApp.cache.get('records') # => nil
        #
        def flush
          @backend.flushdb
        end

        ##
        # Redis has a ton of powerful features (see:
        # https://github.com/redis/redis-rb), which we can't use due
        # to how strict the cache library is. This method catches all method calls and
        # tries to pass them on the redis gem.
        #
        def method_missing(name, *args, &block)
          if @backend.respond_to?(name)
            @backend.send(name, *args, &block)
          else
            super
          end
        end
      end
    end
  end
end
