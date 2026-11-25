require 'digest'
require 'securerandom'

module Padrino
  module Cache
    ##
    # Helpers supporting page or fragment caching within a request route.
    #
    module Helpers
      ##
      # Page caching is easy to integrate into your application. To turn it on, simply provide the
      # <tt>cache: true</tt> option on either a controller or one of its routes.
      # By default, cached content is persisted with a "file store" --that is, in a
      # subdirectory of your application root.
      #
      # @example
      #   # Setting content expiry time.
      #   class CachedApp < Padrino::Application
      #     enable :caching          # turns on caching mechanism
      #
      #     controller '/blog', cache: true do
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
        #   controller '/blog', cache: true do
        #     expires 15
        #
        #     get '/entries' do
        #       'Just broke up eating twinkies, lol'
        #     end
        #   end
        #
        # @api public
        def expires(time)
          @_cache_expires = time
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
        #   controller '/blog', cache: true do
        #
        #     get '/post/:id' do
        #       cache_key :my_name
        #       @post = Post.find(params[:id])
        #     end
        #   end
        #
        # @example
        #     get '/foo', cache: true do
        #       cache_key { param[:id] }
        #       "My id is #{param[:id}"
        #     end
        #   end
        #
        def cache_key(name = nil, &block)
          raise 'Can not provide both cache_key and a block' if name && block

          @_cache_key = name || block
          # A Symbol or a block is the same for every request, so later requests can look it up before the
          # handler runs. Any other key (a String built from params) belongs to this request only.
          page_cache_route.cache_key = @_cache_key if @_cache_key.is_a?(Symbol) || @_cache_key.is_a?(Proc)
        end

        CACHED_VERBS = { 'GET' => true, 'HEAD' => true }.freeze
        WARNED_DUPLICATE_ROUTES = {}
        WARNED_DUPLICATE_ROUTES_MUTEX = Mutex.new

        def self.claim_duplicate_warning(key)
          WARNED_DUPLICATE_ROUTES_MUTEX.synchronize do
            return false if WARNED_DUPLICATE_ROUTES[key]

            WARNED_DUPLICATE_ROUTES[key] = true
          end
        end

        def self.padrino_route_added(route, verb, *)
          return unless route.cache && CACHED_VERBS[verb]

          # Remember the key and expiry set before this route (by an app-level before filter), so a route
          # reached through pass starts from them rather than from this route's.
          route.before_filters { @_cache_outer = [@_cache_key, @_cache_expires] }
          # The lookup is the route's last condition: it runs after every before filter and condition, so
          # access checks written there apply to cached pages too.
          route.custom_conditions << instance_method(:serve_cached_response)

          route.after_filters do
            save_cached_response(@_cache_expires.nil? ? route.cache_expires : @_cache_expires) if settings.caching?
            @_cache_key, @_cache_expires = @_cache_outer
          end
        end

        private

        def serve_cached_response
          @_cache_lookup_key = @_cache_key
          @_cache_lookup_format = negotiated_cache_format
          if settings.caching? && page_cache_route.cache_lookup && (cached_response = load_cached_response)
            env['sinatra.route'] = "#{request.request_method} #{@route.sinatra_pattern}"
            content_type cached_response[:content_type]
            halt 200, cached_response[:body]
          end
          true
        end

        def load_cached_response
          began_at = Time.now
          route_cache_key = page_cache_key
          return unless route_cache_key

          value = settings.cache[route_cache_key]
          page = value if value.is_a?(Hash) && value[:body].is_a?(String)
          logger.bench 'GET Cache', began_at, route_cache_key if defined?(logger) && logger.respond_to?(:bench) && logger.debug? && page

          page
        end

        def save_cached_response(cache_expires)
          return unless @_response_buffer.is_a?(String)

          began_at = Time.now
          route_cache_key = page_cache_key
          return unless route_cache_key

          content = {
            body: @_response_buffer,
            content_type: response.content_type
          }

          settings.cache.store(route_cache_key, content, expires: cache_expires)
          # The lookup runs before the handler, so it can only use a key set by then (or one the route recorded
          # from an earlier request). Look pages up once that key is the one this page was stored under.
          target = page_cache_route
          target.cache_lookup = (@_cache_key || target.cache_key) == (@_cache_lookup_key || target.cache_key)

          logger.bench 'SET Cache', began_at, route_cache_key if defined?(logger) && logger.respond_to?(:bench) && logger.debug?
        end

        def page_cache_route
          @route.get_route || @route
        end

        def negotiated_cache_format
          formats = page_cache_route.provided_formats&.flatten
          return unless formats && !formats.empty?

          format = content_type
          format if formats.include?(:any) || formats.include?(format)
        end

        # The key a page is kept under: an explicit cache_key as given, or the request path
        # with a namespace digest for the app, mount, route, host (for host: routes), format
        # (for provides: routes), and optional cache_namespace.
        def page_cache_key
          explicit_key = resolve_cache_key
          return explicit_key if explicit_key

          target = page_cache_route
          script_name, router_host = page_cache_mount
          req_host = target.host ? request.host.to_s.downcase : nil
          format_part = @_cache_lookup_format
          settings.page_cache_default_key(target, env['PATH_INFO'], script_name, router_host, req_host, format_part)
        end

        ##
        # Resolve the cache_key when it's a block in the correct context.
        #
        def resolve_cache_key
          key = @_cache_key || page_cache_route.cache_key
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

          ##
          # Builds the default namespaced page cache key for +target+ and +path_info+,
          # or returns nil if +target+ is not registered on this app's routers.
          #
          # @api private
          def page_cache_default_key(target, path_info, script_name, router_host, req_host, format_part)
            pair = page_cache_route_token(target)
            return unless pair
            return "#{pair[1]}#{path_info}" if script_name.empty? && router_host.nil? && req_host.nil? && format_part.nil?

            digest = Digest::SHA256.hexdigest([pair[0], script_name, router_host, req_host, format_part].join("\0"))[0, 16]
            "@#{digest}#{path_info}"
          end

          private

          def page_cache_namespace_key
            cache_namespace&.to_s if respond_to?(:cache_namespace)
          end

          def page_cache_route_token(target)
            ns = page_cache_namespace_key
            memo = @_page_cache_tokens
            pair = memo[1][target] if memo && memo[0] == ns
            return pair if pair

            rebuild_page_cache_tokens![target]
          end

          def rebuild_page_cache_tokens!
            tokens = {}.compare_by_identity
            app_before_count = total_app_before_filters
            app_id = respond_to?(:app_name) ? app_name.to_s : nil
            class_id = name || (@_page_cache_anon_id ||= SecureRandom.hex(16))
            ns = page_cache_namespace_key
            source_cache = {}
            depth = 0
            cls = self
            while cls.respond_to?(:router)
              r = cls.compiled_router
              base_counts = Hash.new(0)
              r.routes.sort_by(&:order).each do |route|
                next unless route.cache && CACHED_VERBS[route.verb] && route.get_route.nil?

                base_token = compute_route_base_token(route, class_id, app_id, app_before_count, depth, ns, source_cache)
                ordinal = base_counts[base_token]
                base_counts[base_token] = ordinal + 1

                if ordinal == 1 && route.cache_key.nil?
                  path_key = route.original_path.is_a?(Regexp) ? [:regexp, route.original_path.source, route.original_path.options] : route.original_path
                  if Page.claim_duplicate_warning([cls.name || cls.object_id, route.verb, path_key])
                    display_path = route.original_path == '' ? '/' : route.original_path
                    warn "[padrino-cache] #{cls}: multiple cache: true routes share #{route.verb} #{display_path.inspect} " \
                         'with indistinguishable matchers or condition blocks; give each a unique route name so ' \
                         'reordering routes does not change their cache keys.'
                  end
                end

                static_token = Digest::SHA256.hexdigest("#{base_token}:#{ordinal}").freeze
                default_prefix = "@#{static_token[0, 16]}".freeze
                tokens[route] = [static_token, default_prefix].freeze
              end
              depth += 1
              cls = cls.superclass
            end
            tokens.freeze
            @_page_cache_tokens = [ns, tokens].freeze
            tokens
          end

          def total_app_before_filters
            total = 0
            cls = self
            while cls.respond_to?(:router)
              total += cls.filters[:before].size if cls.respond_to?(:filters)
              cls = cls.superclass
            end
            total
          end

          def compute_route_base_token(route, class_id, app_id, app_before_count, depth, namespace, source_cache)
            sha = Digest::SHA256.new
            digest_cache_value(sha, class_id, 0, source_cache)
            digest_cache_value(sha, app_id, 0, source_cache)
            sha << "B#{app_before_count}:D#{depth}:R#{route.verb}:#{route.custom_conditions.size}:#{route.before_filters.size}:"
            digest_cache_value(sha, route.name, 0, source_cache)
            digest_cache_value(sha, route.original_path, 0, source_cache)
            digest_cache_value(sha, route.host, 0, source_cache)
            digest_cache_value(sha, route.user_agent, 0, source_cache)
            digest_cache_value(sha, route.provided_formats, 0, source_cache)
            digest_cache_value(sha, route.capture, 0, source_cache)
            digest_cache_value(sha, route.condition_options, 0, source_cache)
            digest_cache_value(sha, namespace, 0, source_cache) unless namespace.nil?
            sha.hexdigest
          end

          def digest_cache_value(sha, value, depth = 0, source_cache = nil)
            return sha << 'X;' if depth > 8

            case value
            when nil then sha << 'N;'
            when true then sha << 'T;'
            when false then sha << 'F;'
            when Integer then sha << "I#{value};"
            when Float then sha << "D#{value};"
            when Symbol
              s = value.to_s
              sha << "Y#{s.bytesize}:" << s << ';'
            when String
              sha << "S#{value.bytesize}:" << value << ';'
            when Regexp
              s = value.source
              sha << "G#{value.options}:#{s.bytesize}:" << s << ';'
            when Array
              sha << "A#{value.size}["
              value.each { |item| digest_cache_value(sha, item, depth + 1, source_cache) }
              sha << ']'
            when Hash
              sha << "H#{value.size}{"
              value.sort_by { |k, _| [k.class.name.to_s, k.to_s] }.each do |k, v|
                digest_cache_value(sha, k, depth + 1, source_cache)
                digest_cache_value(sha, v, depth + 1, source_cache)
              end
              sha << '}'
            when Range
              sha << (value.exclude_end? ? 'E(' : 'B(')
              digest_cache_value(sha, value.begin, depth + 1, source_cache)
              digest_cache_value(sha, value.end, depth + 1, source_cache)
              sha << ')'
            when Proc
              loc = value.source_location
              sha << 'P'
              digest_cache_value(sha, loc, depth + 1, source_cache)
              digest_cache_value(sha, proc_source_line(loc, source_cache), depth + 1, source_cache)
            when Module
              name = value.name || 'anon'
              sha << "M#{name.bytesize}:" << name << ';'
            else
              name = value.class.name || 'anon'
              sha << "O#{name.bytesize}:" << name << ';'
            end
          end

          def proc_source_line(loc, source_cache)
            return unless loc && loc[0].is_a?(String) && loc[1].is_a?(Integer) && loc[1].positive?

            path = loc[0]
            lines = if source_cache
                      source_cache.fetch(path) do
                        source_cache[path] = read_source_lines(path)
                      end
                    else
                      read_source_lines(path)
                    end
            lines ? lines[loc[1] - 1] : nil
          end

          def read_source_lines(path)
            File.file?(path) ? File.readlines(path, encoding: Encoding::BINARY) : false
          rescue StandardError
            false
          end
        end

        module RoutingClassMethods
          def compiled_router
            was_deferred = !@deferred_routes.nil?
            result = super
            rebuild_page_cache_tokens! if was_deferred
            result
          end

          def reset_router!
            @_page_cache_tokens = nil
            super
          end
        end
      end
    end
  end
end
