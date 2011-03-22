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
        # ==== Examples
        #   Padrino::Cache::Store::Redis.new ::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0)
        #
        def initialize(client)
          @backend = client
        end

        def get(key)
          @backend.get(key)
        end

        def set(key, value, opts = nil)
          if opts && opts[:expires_in]
            expires_in = opts[:expires_in].to_i
            @backend.setex(key, expires_in, value)
          else
            @backend.set(key, value)
          end
        end

        def delete(key)
          @backend.del(key)
        end

        def flush
          @backend.flushdb
        end
      end # Redis
    end # Store
  end # Cache
end # Padrino