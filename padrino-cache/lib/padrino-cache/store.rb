module Padrino
  module Cache
    module Store
      autoload :File,     'padrino-cache/store/file'
      autoload :Memcache, 'padrino-cache/store/memcache'
    end
  end
end
