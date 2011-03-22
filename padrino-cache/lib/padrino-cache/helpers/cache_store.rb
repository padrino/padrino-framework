module Padrino
  module Cache
    module Helpers
      module CacheStore #:nodoc:
        def expire(*key)
          if key.size == 1 and key.first.is_a?(String)
            self.class.cache.delete(key)
          else
            self.class.cache.delete(self.class.url(*key))
          end
        end
      end # CacheStore
    end # Helpers
  end # Cache
end # Padrino