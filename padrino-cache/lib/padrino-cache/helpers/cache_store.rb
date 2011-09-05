module Padrino
  module Cache
    module Helpers
      module CacheStore # @private

        # @api private
        def expire(*key)
          if key.size == 1 and key.first.is_a?(String)
            settings.cache.delete(key)
          else
            settings.cache.delete(self.class.url(*key))
          end
        end
      end # CacheStore
    end # Helpers
  end # Cache
end # Padrino
