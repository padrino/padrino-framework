module Padrino
  module Cache
    module Helpers
      ##
      # Page caching is easy to integrate into your application. To turn it on, simply provide the
      # <tt>:cache => true</tt> option on either a controller or one of its routes.
      # By default, cached content is persisted with a "file store"--that is, in a
      # subdirectory of your application root.
      #
      # ==== Examples
      #   # Setting content expiry time
      #   class CachedApp < Padrino::Application
      #     enable :caching          # turns on caching mechanism
      #
      #     controller '/blog', :cache => true do
      #       expires_in 15
      #
      #       get '/entries' do
      #         # expires_in 15 => can also be defined inside a single route
      #         'just broke up eating twinkies lol'
      #       end
      #
      #       get '/post/:id' do
      #         cache_key :my_name
      #         @post = Post.find(params[:id])
      #       end
      #     end
      #   end
      #
      # You can manually expire cache with CachedApp.cache.delete(:my_name)
      #
      # Note that the "latest" method call to <tt>expires_in</tt> determines its value: if
      # called within a route, as opposed to a controller definition, the route's
      # value will be assumed.
      #
      module Page
        ##
        # This helper is used within a controller or route to indicate how often content
        # should persist in the cache.
        #
        # After <tt>seconds</tt> seconds have passed, content previously cached will
        # be discarded and re-rendered. Code associated with that route will <em>not</em>
        # be executed; rather, its previous output will be sent to the client with a
        # 200 OK status code.
        #
        def expires_in(time)
          @_last_expires_in = time
        end

        ##
        # This helper is used within a route or route to indicate the name in the cache.
        #
        def cache_key(name)
          @_cache_key = name
        end

        def self.padrino_route_added(route, verb, path, args, options, block) #:nodoc:
          if route.cache and %w(GET HEAD).include?(verb)
            route.add_before_filter(Proc.new {
              if settings.caching?
                began_at = Time.now
                value = settings.cache.get(@_cache_key || env['PATH_INFO'])
                @_cache_key = nil
                logger.debug "GET Cache (%0.4fms) %s" % [Time.now-began_at, env['PATH_INFO']] if defined?(logger) && value
                halt 200, value if value
              end
            })
            route.add_after_filter(Proc.new { |_|
              if settings.caching?
                began_at = Time.now
                if @_last_expires_in
                  settings.cache.set(@_cache_key || env['PATH_INFO'], @_response_buffer, :expires_in => @_last_expires_in)
                  @_last_expires_in = nil
                else
                  settings.cache.set(@_cache_key || env['PATH_INFO'], @_response_buffer)
                end
                @_cache_key = nil
                logger.debug "SET Cache (%0.4fms) %s" % [Time.now-began_at, env['PATH_INFO']] if defined?(logger)
              end
            })
          end
        end
      end # Page
    end # Helpers
  end # Cache
end # Padrino