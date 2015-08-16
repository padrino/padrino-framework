module Padrino
  module Cache
    module Helpers
      module ObjectCache
        def cache_object(key, opts = {})
          if settings.caching?
            began_at = Time.now
            if settings.cache.key?(key.to_s)
              value = settings.cache[key.to_s]
              logger.debug "GET Object", began_at, key.to_s if defined?(logger)
            else
              value = yield
              settings.cache.store(key.to_s, value, opts)
              logger.debug "SET Object", began_at, key.to_s if defined?(logger)
            end
            value
          else
            yield
          end
        end
      end
    end
  end
end
