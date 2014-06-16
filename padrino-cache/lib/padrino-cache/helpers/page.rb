module Padrino
  module Cache
    ##
    # Helpers supporting page or fragment caching within a request route.
    #
    module Helpers
      ##
      # Page caching is easy to integrate into your application. To turn it on, simply provide the
      # <tt>:cache => true</tt> option on either a controller or one of its routes.
      # By default, cached content is persisted with a "file store" --that is, in a
      # subdirectory of your application root.
      #
      # @example
      #   # Setting content expiry time.
      #   class CachedApp < Padrino::Application
      #     enable :caching          # turns on caching mechanism
      #
      #     controller '/blog', :cache => true do
      #       expires 15
      #
      #       get '/entries' do
      #         # expires 15 => can also be defined inside a single route
      #         'Just broke up eating twinkies, lol'
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
      # Note that the "latest" method call to <tt>expires</tt> determines its value: if
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
        #     expires 15
        #
        #     get '/entries' do
        #       'Just broke up eating twinkies, lol'
        #     end
        #   end
        #
        # @api public
        def expires(time)
          @route.cache_expires = time if @route
          @_last_expires       = time
        end

        def expires_in(time)
          warn 'expires_in has been deprecated in favour of expires'
          expires(time)
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
        #       "My id is #{param[:id}"
        #     end
        #   end
        #
        def cache_key(name = nil, &block)
          raise "Can not provide both cache_key and a block" if name && block
          @route.cache_key = block_given? ? block : name
        end

        def self.padrino_route_added(route, verb, path, args, options, block)
          if route.cache and %w(GET HEAD).include?(verb)
            route.before_filters do
              if settings.caching?
                began_at = Time.now

                route_cache_key = resolve_cache_key || env['PATH_INFO']
                value = settings.cache[route_cache_key]
                logger.debug "GET Cache", began_at, route_cache_key if defined?(logger) && value

                if value.kind_of?(Hash)
                  content_type value[:content_type]
                  halt 200, value[:body]
                elsif value
                  halt 200, value
                end
              end
            end

            route.after_filters do
              if settings.caching? && @_response_buffer.kind_of?(String)
                began_at = Time.now
                content = {
                  :body         => @_response_buffer,
                  :content_type => @_content_type
                }
                route_cache_key = resolve_cache_key || env['PATH_INFO']

                if @_last_expires
                  settings.cache.store(route_cache_key, content, :expires => @_last_expires)
                  @_last_expires = nil
                else
                  settings.cache.store(route_cache_key, content)
                end

                logger.debug "SET Cache", began_at, route_cache_key if defined?(logger)
              end
            end
          end
        end

        private
        ##
        # Resolve the cache_key when it's a block in the correct context.
        #
        def resolve_cache_key
          @route.cache_key.is_a?(Proc) ? instance_eval(&@route.cache_key) : @route.cache_key
        end
      end
    end
  end
end
