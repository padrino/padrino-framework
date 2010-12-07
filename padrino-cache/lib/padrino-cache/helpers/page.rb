module Padrino
  module Cache
    module Helpers
      module Page
        def expires_in(time)
          @_last_expires_in = time
        end

        def self.padrino_route_added(route, verb, path, args, options, block)
          if route.cache and %w(GET HEAD).include?(verb)
            route.add_before_filter(Proc.new {
              if self.class.caching?
                value = self.class.cache_store.get(route.cache.respond_to?(:call) ? route.cache.call(request) : env['PATH_INFO'])
                halt 200, value if value
              end
            })
            route.add_after_filter(Proc.new { |something|
              if self.class.caching?
                if @_last_expires_in
                  self.class.cache_store.set(route.cache.respond_to?(:call) ? route.cache.call(request) : env['PATH_INFO'], @_response_buffer, :expires_in => @_last_expires_in)
                  @_last_expires_in = nil
                else
                  self.class.cache_store.set(route.cache.respond_to?(:call) ? route.cache.call(request) : env['PATH_INFO'], @_response_buffer)
                end
              end
            })
          end
        end
      end # Page
    end # Helpers
  end # Cache
end # Padrino