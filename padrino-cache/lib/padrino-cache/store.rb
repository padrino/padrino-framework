module Padrino
  module Cache
    module Store
      EXPIRES_EDGE = 86400

      autoload :File,     'padrino-cache/store/file'
      autoload :Memcache, 'padrino-cache/store/memcache'
    end
  end
end
