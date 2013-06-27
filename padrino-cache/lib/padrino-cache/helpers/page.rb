module Padrino
  module Cache
    ##
    # Helpers supporting page or fragment caching within a request route.
    #
    module Helpers
      ##
      # Page caching is easy to integrate into your application. To turn it on, simply provide the
      # <tt>:cache => true</tt> option on either a controller or one of its routes.
      # By default, cached content is persisted with a "file store"--that is, in a
      # subdirectory of your application root.
      #
      # @example
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
        # @param [Integer] time
        #   Time til expiration (seconds)
        #
        # @example
        #   controller '/blog', :cache => true do
        #     expires_in 15
        #
        #     get '/entries' do
        #       # expires_in 15 => can also be defined inside a single route
        #       'just broke up eating twinkies lol'
        #     end
        #   end
        #
        # @api public
        def expires_in(time)
          @route.cache_expires_in = time if @route
          @_last_expires_in       = time
        end

        ##
        # This helper is used within a route or route to indicate the name in the cache.
        #
        # @param [Symbol] name
        #   cache key
        # @param [Proc] block
        #   block to be evaluated to cache key
        #
        # @example
        #   controller '/blog', :cache => true do
        #
        #     get '/post/:id' do
        #       cache_key :my_name
        #       @post = Post.find(params[:id])
        #     end
        #   end
        #
        # @example
        #     get '/foo', :cache => true do
        #       cache_key { param[:id] }
        #       "my id is #{param[:id}"
        #     end
        #   end
        #
        # @api public
        def cache_key(name = nil, &block)
          raise "Can not provide both cache_key and a block"
          @route.cache_key = block_given? ? block : name
        end

        # @private
        def self.padrino_route_added(route, verb, path, args, options, block) # @private
          if route.cache and %w(GET HEAD).include?(verb)
            route.before_filters do
              if settings.caching?
                began_at     = Time.now
                resolved_key = @route.cache_key.is_a?(Proc) ? instance_eval(&@route.cache_key) : @route.cache_key

                value = settings.cache.get(resolved_key || env['PATH_INFO'])
                logger.debug "GET Cache", began_at, @route.cache_key || env['PATH_INFO'] if defined?(logger) && value

                if value
                  # content_type(value[:content_type]) if value[:content_type]
                  halt 200, value
                end
              end
            end

            route.after_filters do
              if settings.caching? && @_response_buffer.kind_of?(String)
                began_at     = Time.now
                content      = @_response_buffer
                resolved_key = @route.cache_key.is_a?(Proc) ? instance_eval(&@route.cache_key) : @route.cache_key

                if @_last_expires_in
                  settings.cache.set(resolved_key || env['PATH_INFO'], content, :expires_in => @_last_expires_in)
                  @_last_expires_in = nil
                else
                  settings.cache.set(resolved_key || env['PATH_INFO'], content)
                end

                logger.debug "SET Cache", began_at, @route.cache_key || env['PATH_INFO'] if defined?(logger)
              end
            end
          end
        end
      end # Page
    end # Helpers
  end # Cache
end # Padrino
