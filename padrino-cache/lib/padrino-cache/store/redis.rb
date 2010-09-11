begin
  require 'redis'
rescue LoadError
  raise "You must install redis to use the Redis cache store backend"
end

module Padrino
  module Cache
    module Store
      class Redis
        def initialize(*args)
          @backend = ::Redis.new(*args)
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

        def flushall
          @backend.flushall
        end

        def shutdown
          @backend.shutdown
        end
      end # Redis
    end # Store
  end # Cache
end # Padrino
