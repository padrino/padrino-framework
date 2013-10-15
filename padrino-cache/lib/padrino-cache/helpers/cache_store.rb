module Padrino
  module Cache
    module Helpers
      module CacheStore
        def expire(*key)
          if key.size == 1 and (key.first.is_a?(String) or key.first.is_a?(Symbol))
            settings.cache.delete(key.first)
          else
            settings.cache.delete(self.class.url(*key))
          end
          nil
        end
      end
    end
  end
end
