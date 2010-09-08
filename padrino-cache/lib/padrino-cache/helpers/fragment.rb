module Padrino
  module Cache
    module Helpers
      module Fragment
        include Padrino::Helpers::OutputHelpers

        def cache(key, &block)
          if value = self.class.cache_store.get(key)
            concat_content(value)
          else
            value = capture_html(&block)
            self.class.cache_store.set(key, value)
            concat_content(value)
          end
        end
      end
    end
  end
end