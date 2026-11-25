module Padrino
  module Cache
    module Helpers
      module CacheStore
        HOST_LABEL = '[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?'.freeze
        SINGLE_HOST_LABEL = /\A#{HOST_LABEL}\z/i
        HOST_PREFIX = /\A(?:localhost|#{HOST_LABEL}(?:\.#{HOST_LABEL})+|\[[0-9a-f:]+\])\z/i

        def expire(*key)
          if (key.size == 1) && (key.first.is_a?(String) || key.first.is_a?(Symbol))
            raw = key.first
            settings.cache.delete(raw)
            expire_matching_pages(raw, strip_mount: false) if raw.is_a?(String)
          else
            url_path = self.class.url(*key)
            settings.cache.delete(url_path)
            expire_matching_pages(url_path, strip_mount: true)
          end
          nil
        end

        ##
        # The mount (SCRIPT_NAME and router host mapping) this request arrived through, taken when
        # the request starts so that code running after the router returns (a stream block) sees it.
        #
        # @api private
        def page_cache_mount
          @_page_cache_mount ||= [env['SCRIPT_NAME'].to_s, env['padrino.router.host']].freeze
        end

        private

        def expire_matching_pages(target, strip_mount:)
          return unless env && target.valid_encoding? && Encoding.compatible?(target, '/') &&
                        settings.respond_to?(:router) && settings.respond_to?(:page_cache_default_key)

          script_name, router_host = page_cache_mount

          if target.start_with?('/')
            path_info = strip_mount ? strip_mount_prefix(target, mount_prefix) : target
            expire_routes_for(path_info, script_name, router_host, nil)
          elsif target.include?('/')
            host_part, rest = target.split('/', 2)
            return unless host_part.ascii_only?

            downcased = host_part.downcase
            return unless HOST_PREFIX.match?(downcased) || single_label_cached_host?(downcased)

            expire_routes_for("/#{rest}", script_name, router_host, downcased)
          end
        end

        def single_label_cached_host?(host)
          return false unless SINGLE_HOST_LABEL.match?(host)

          cls = settings
          while cls.respond_to?(:router)
            cls.compiled_router.routes.each do |route|
              next unless route.cache && route.get_route.nil? && route.host
              return true if Array(route.host).any? { |h| h.is_a?(String) && h.casecmp?(host) }
            end
            cls = cls.superclass
          end
          false
        end

        def mount_prefix
          settings.respond_to?(:uri_root) ? settings.uri_root.to_s.sub(%r{/+\z}, '') : ''
        end

        def strip_mount_prefix(target, prefix)
          return target if prefix.empty?
          return '/' if target == prefix
          return target.delete_prefix(prefix) if target.start_with?("#{prefix}/")

          target
        end

        def expire_routes_for(path_info, script_name, router_host, explicit_host)
          seen = {}.compare_by_identity
          cls = settings
          while cls.respond_to?(:router)
            %w[GET HEAD].each do |verb|
              cls.compiled_router.recognize('REQUEST_METHOD' => verb, 'PATH_INFO' => path_info).each do |route|
                target_route = route.get_route || route
                next unless target_route.cache && !seen[target_route]

                seen[target_route] = true
                expire_route_keys(target_route, path_info, script_name, router_host, explicit_host)
              end
            end
            cls = cls.superclass
          end
        end

        def expire_route_keys(target_route, path_info, script_name, router_host, explicit_host)
          if target_route.host
            return unless explicit_host && host_matches?(target_route.host, explicit_host)

            req_host = explicit_host
          else
            return if explicit_host

            req_host = nil
          end

          formats = target_route.provided_formats&.flatten
          if formats && !formats.empty?
            return if formats.include?(:any)

            (formats.uniq + [nil]).each do |fmt|
              delete_default_page_key(target_route, path_info, script_name, router_host, req_host, fmt)
            end
          else
            delete_default_page_key(target_route, path_info, script_name, router_host, req_host, nil)
          end
        end

        def delete_default_page_key(target_route, path_info, script_name, router_host, req_host, format_part)
          key = settings.page_cache_default_key(target_route, path_info, script_name, router_host, req_host, format_part)
          settings.cache.delete(key) if key
        end
      end
    end
  end
end
