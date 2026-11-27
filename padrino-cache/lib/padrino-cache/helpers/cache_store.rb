module Padrino
  module Cache
    module Helpers
      module CacheStore
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
            return if host_part.empty? || !host_part.ascii_only?

            expire_routes_for("/#{rest}", script_name, router_host, host_part)
          end
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

        # Host names are case-insensitive, so a Regexp host: matches the expire argument ignoring case.
        # A Proc host: is left alone: it only ever sees request hosts.
        def expire_host_matches?(hosts, host)
          Array(hosts).any? do |pattern|
            if pattern.is_a?(Regexp)
              Regexp.new(pattern.source, pattern.options | Regexp::IGNORECASE).match?(host)
            elsif pattern.is_a?(Proc)
              false
            else
              host_matches?(pattern, host) || host_matches?(pattern, host.downcase)
            end
          end
        end

        def expire_route_keys(target_route, path_info, script_name, router_host, explicit_host)
          if target_route.host
            return unless explicit_host && expire_host_matches?(target_route.host, explicit_host)

            req_host = explicit_host.downcase
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
