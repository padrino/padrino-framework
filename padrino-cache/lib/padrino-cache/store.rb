module Padrino
  module Cache
    ##
    # Defines the available storage adapters for persisting the cache.
    #
    module Store
      # The defined duration for the expiration edge.
      EXPIRES_EDGE = 86400

      autoload :File,     'padrino-cache/store/file'
      autoload :Memcache, 'padrino-cache/store/memcache'
      autoload :Memory,   'padrino-cache/store/memory'
      autoload :Redis,    'padrino-cache/store/redis'
      autoload :Mongo,    'padrino-cache/store/mongo'
    end # Store
  end # Cache
end # Padrino
