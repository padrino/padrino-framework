module Padrino
  module Cache
    module Helpers
      module Page
        def self.padrino_route_added(route, verb, path, args, options, block)
          if route.cache
            raise "Cachable routes must be GET or HEAD" unless %w(GET HEAD).include?(verb)
            route.add_before_filter(Proc.new {
              value = self.class.cache_store.get(env['PATH_INFO'])
              halt 200, value if value
            })
            route.add_after_filter(Proc.new { |something| 
              self.class.cache_store.set(request.env['PATH_INFO'], @_response_buffer)
            })
          end
        end
      end
    end
  end
end