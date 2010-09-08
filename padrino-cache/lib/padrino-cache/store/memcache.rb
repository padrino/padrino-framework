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

        def set(key, value)
          @backend.set(key, value)
        end

        def delete(key)
          @backend.delete(key)
        end
      end
    end
  end
end