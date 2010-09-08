module Padrino
  module Cache
    module Helpers
      module Page
        def self.padrino_route_added(route, verb, path, args, options, block)
          if route.cache and %w(GET HEAD).include?(verb)
            route.add_before_filter(Proc.new {
              value = self.class.cache_store.get(route.cache.respond_to?(:call) ? route.cache.call(env) : env['PATH_INFO'])
              halt 200, value if value
            })
            route.add_after_filter(Proc.new { |something| 
              self.class.cache_store.set(route.cache.respond_to?(:call) ? route.cache.call(env) : env['PATH_INFO'], @_response_buffer)
            })
          end
        end
      end
    end
  end
end