module Padrino
  module Cache
    module Helpers
      module Fragment
        include Padrino::Helpers::OutputHelpers

        def cache(key, opts = nil, &block)
          if self.class.caching?
            if value = self.class.cache_store.get(key.to_s)
              concat_content(value)
            else
              value = capture_html(&block)
              self.class.cache_store.set(key.to_s, value, opts)
              concat_content(value)
            end
          end
        end
      end # Fragment
    end # Helpers
  end # Cache
end # Padrino
