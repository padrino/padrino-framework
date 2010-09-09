module Padrino
  module Cache
    module Helpers
      module CacheStore
        def expire(*key)
          if key.size == 1 and key.first.is_a?(String)
            self.class.cache_store.delete(key)
          else
            self.class.cache_store.delete(self.class.url(*key))
          end
        end
      end
    end
  end
end