# require 'padrino-core/support_lite'
Dir[File.dirname(__FILE__) + '/padrino-routing/**/*.rb'].each {|file| require file }

module Padrino
  class RouteNotFound < RuntimeError;    end
  class InvalidNameSpace < RuntimeError; end

  module Routing
    def self.registered(app)
      # Named paths stores the named route aliases mapping to the url
      # i.e { [:account] => '/account/path', [:admin, :show] => '/admin/show/:id' }
      app.set :named_paths, {}
      app.set :app_name, app.name.underscore.to_sym unless app.respond_to?(:app_name)
      app.set :uri_root, '/' unless app.respond_to?(:uri_root)
      app.helpers Padrino::Routing::Helpers

      # map constructs a mapping between a named route and a specified alias
      # the mapping url can contain url query parameters
      # map(:accounts).to('/accounts/url')
      # map(:admin, :show).to('/admin/show/:id')
      # map(:admin) { |namespace| namespace.map(:show).to('/admin/show/:id') }
      def map(*names, &block)
        named_router = Padrino::Routing::NamedRoute.new(self, *names)
        block_given? ? block.call(named_router) : named_router
      end

      # Used to define namespaced route configurations in order to group similar routes
      # Class evals the routes but with the namespace assigned which will append to each route
      # namespace(:admin) { get(:show) { "..." } }
      def namespace(*args, &block)
        if namespace = args.find { |ns| !ns.kind_of?(Symbol) }
          raise InvalidNameSpace, "The name space #{namespace.inspect} must be a symbol"
        else
          original, @_namespaces = @_namespaces, args
          self.class_eval(&block)
          @_namespaces = original
        end
      end

      # Hijacking route method in Sinatra to replace a route alias (i.e :account) with the full url string mapping
      # Supports namespaces by accessing the instance variable and appending this to the route alias name
      # If the path is not a symbol, nothing is changed and the original route method is invoked
      def route(verb, path, options={}, &block)
        if path.kind_of?(Symbol)
          route_name = [@_namespaces, path].flatten.compact
          if mapped_url = options.delete(:map) # constructing named route
            map(*route_name).to(mapped_url)
            path = mapped_url
          else # referencing prior named route
            path = named_paths[route_name.dup.unshift(self.app_name.to_sym)]
          end
          # If here we don't have a path we autobuild them
          unless path
            mapped_url = "/" + route_name.join("/")
            map(*route_name).to(mapped_url)
            path = mapped_url
          end
        end
        super verb, path, options, &block
      end
    end
  end
end
