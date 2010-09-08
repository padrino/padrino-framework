begin
  require 'memcached'
rescue LoadError
  raise "You must install memecached to use the Memecache cache store backend"
end

module Padrino
  module Cache
    module Store
      class File
        def initialize(*args)
          @backend = Memcached.new(*args)
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
      end
    end
  end
end