module Padrino
  module Routing
    class NamedRoute
      # Constructs the NamedRoute which accepts the application and
      # the route alias names to register (i.e [:account] or [:admin, :show])
      # NamedRoute.new(@app, :admin, :show)
      def initialize(app, *names)
        @app   = app
        @names = names.flatten
      end

      # Used to define the url mapping to the supplied alias
      # Appends the application name to front of route if necessary
      # NamedRoute.new(@app, :account).to('/account/path')
      def to(path)
        @names.unshift(@app.app_name.to_sym) unless @names.first == @app.app_name.to_sym
        @app.named_paths[@names] = path
      end

      # Used to define the url mappings for child aliases within a namespace
      # Invokes map on the application itself, appending the namespace to the route
      # NamedRoute.new(@app, :admin).map(:show).to('/admin/show')
      # is equivalent to NamedRoute.new(@app, :admin, :show).to('/admin/show')
      def map(*args, &block)
        @app.map(*args.unshift(@names), &block)
      end
    end
  end
end
