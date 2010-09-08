module Padrino
  module Cache
    module Helpers
      module CacheStore
        def expire(key)
          self.class.cache_store.delete(key)
        end
      end
    end
  end
end