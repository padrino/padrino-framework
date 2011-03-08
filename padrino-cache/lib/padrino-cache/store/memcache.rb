module Padrino
  module Cache
    module Store
      class Memcache
        # Initialize Memcache store with client connection.
        # Padrino::Cache::Store::Memcache.new ::Memcached.new('127.0.0.1:11211')
        #
        def initialize(client)
          @backend = client
        rescue
          raise
        end

        def get(key)
          @backend.get(key)
        rescue Memcached::NotFound
          nil
        end

        def set(key, value, opts = nil)
          if opts && opts[:expires_in]
            expires_in = opts[:expires_in].to_i
            expires_in = Time.new.to_i + expires_in if expires_in < EXPIRES_EDGE
            @backend.set(key, value, expires_in)
          else
            @backend.set(key, value)
          end
        end

        def delete(key)
          @backend.delete(key)
        end

        def flush
          @backend.flush
        end
      end # Memcached
    end # Store
  end # Cache
end # Padrino
