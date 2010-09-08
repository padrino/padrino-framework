module Padrino
  module Cache
    module Helpers
      module Fragment
        include Padrino::Helpers::OutputHelpers

        def cache(key, opts = nil, &block)
          if self.class.caching?
            if value = self.class.cache_store.get(key, opts)
              concat_content(value)
            else
              value = capture_html(&block)
              self.class.cache_store.set(key, value, opts)
              concat_content(value)
            end
          end
        end
      end
    end
  end
end