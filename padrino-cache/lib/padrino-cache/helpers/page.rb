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
          @route.cache_expires = time
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
          fail "Can not provide both cache_key and a block" if name && block
          @route.cache_key = name || block
        end

        CACHED_VERBS = { 'GET' => true, 'HEAD' => true }.freeze

        def self.padrino_route_added(route, verb, *)
          return unless route.cache && CACHED_VERBS[verb]

          route.before_filters do
            next unless settings.caching?
            if cached_response = load_cached_response
              content_type cached_response[:content_type]
              halt 200, cached_response[:body]
            end
          end

          route.after_filters do
            save_cached_response(route.cache_expires) if settings.caching?
          end
        end

        private

        def load_cached_response
          began_at = Time.now
          route_cache_key = resolve_cache_key || env['PATH_INFO']

          value = settings.cache[route_cache_key]
          logger.debug "GET Cache", began_at, route_cache_key if defined?(logger) && value

          value
        end

        def save_cached_response(cache_expires)
          return unless @_response_buffer.kind_of?(String)

          began_at = Time.now
          route_cache_key = resolve_cache_key || env['PATH_INFO']

          content = {
            :body         => @_response_buffer,
            :content_type => response.content_type
          }

          settings.cache.store(route_cache_key, content, :expires => cache_expires)

          logger.debug "SET Cache", began_at, route_cache_key if defined?(logger)
        end

        ##
        # Resolve the cache_key when it's a block in the correct context.
        #
        def resolve_cache_key
          key = @route.cache_key
          key.is_a?(Proc) ? instance_eval(&key) : key
        end

        module ClassMethods
          ##
          # A method to set `expires` time inside `controller` blocks.
          #
          # @example
          #   controller :users do
          #     expires 15
          #
          #     get :show do
          #       'shown'
          #     end
          #   end
          #
          def expires(time)
            @_expires = time
          end
        end
      end
    end
  end
end
