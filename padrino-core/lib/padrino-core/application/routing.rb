require 'http_router' unless defined?(HttpRouter)
require 'padrino-core/support_lite' unless defined?(SupportLite)

module Padrino
  ##
  # Padrino provides advanced routing definition support to make routes and url generation much easier.
  # This routing system supports named route aliases and easy access to url paths.
  # The benefits of this is that instead of having to hard-code route urls into every area of your application,
  # now we can just define the urls in a single spot and then attach an alias which can be used to refer
  # to the url throughout the application.
  #
  module Routing
    CONTENT_TYPE_ALIASES = { :htm => :html }

    class ::HttpRouter::Route
      attr_accessor :custom_conditions, :before_filters, :after_filters, :use_layout, :controller
    end

    class ::Sinatra::Request
      attr_accessor :match

      def controller
        route && route.controller
      end

      def route
        match.matched? ? match.path.route : nil
      end
    end

    class UnrecognizedException < RuntimeError #:nodoc:
    end

    ##
    # Main class that register this extension
    #
    class << self
      def registered(app)
        app.send(:include, InstanceMethods)
        app.extend(ClassMethods)
      end
      alias :included :registered
    end

    module ClassMethods
      ##
      # Method for organize in a better way our routes like:
      #
      #   controller :admin do
      #     get :index do; ...; end
      #     get :show, :with => :id  do; ...; end
      #   end
      #
      # Now you can call your actions with:
      #
      #   url(:admin_index) # => "/admin"
      #   url(:admin_show, :id => 1) # "/admin/show/1"
      #
      # You can instead using named routes follow the sinatra way like:
      #
      #   controller "/admin" do
      #     get "/index" do; ...; end
      #     get "/show/:id" do; ...; end
      #   end
      #
      # and you can call directly these urls:
      #
      #   # => "/admin"
      #   # => "/admin/show/1"
      #
      # You can supply provides to all controller routes:
      #
      #   controller :provides => [:html, :xml, :json] do
      #     get :index do; "respond to html, xml and json"; end
      #     post :index do; "respond to html, xml and json"; end
      #     get :foo do; "respond to html, xml and json"; end
      #   end
      #
      # You can specify parent resources in padrino with the :parent option on the controller:
      #
      #   controllers :product, :parent => :user do
      #     get :index do
      #       # url is generated as "/user/#{params[:user_id]}/product"
      #       # url_for(:product, :index, :user_id => 5) => "/user/5/product"
      #     end
      #     get :show, :with => :id do
      #       # url is generated as "/user/#{params[:user_id]}/product/show/#{params[:id]}"
      #       # url_for(:product, :show, :user_id => 5, :id => 10) => "/user/5/product/show/10"
      #     end
      #   end
      #
      # You can supply default values:
      #
      #   controller :lang => :de do
      #     get :index, :map => "/:lang" do; "params[:lang] == :de"; end
      #   end
      #
      # In a controller before and after filters are scoped and didn't affect other controllers or main app.
      # In a controller layout are scoped and didn't affect others controllers and main app.
      #
      #   controller :posts do
      #     layout :post
      #     before { foo }
      #     after  { bar }
      #   end
      #
      def controller(*args, &block)
        if block_given?
          options = args.extract_options!

          # Controller defaults
          @_controller, original_controller = args, @_controller
          @_parents,    original_parent     = options.delete(:parent), @_parents
          @_provides,   original_provides   = options.delete(:provides), @_provides
          @_defaults,   original_defaults   = options, @_defaults

          # Application defaults
          @before_filters, original_before_filters = [],  @before_filters
          @after_filters,  original_after_filters  = [],  @after_filters
          @layout,         original_layout         = nil, @layout

          instance_eval(&block)

          # Application defaults
          @before_filters = original_before_filters
          @after_filters  = original_after_filters
          @layout         = original_layout

          # Controller defaults
          @_controller, @_parents = original_controller, original_parent
          @_defaults, @_provides  = original_defaults, original_provides
        else
          include(*args) if extensions.any?
        end
      end
      alias :controllers :controller

      ##
      # Using HTTPRouter, for features and configurations see: http://github.com/joshbuddy/http_router
      #
      # ==== Examples
      #
      #   router.add('/greedy/{!:greed,.*}')
      #   router.recognize('/simple')
      #
      def router
        unless @router
          @router = HttpRouter.new
        end
        block_given? ? yield(@router) : @router
      end
      alias :urls :router

      ##
      # Instance method for url generation like:
      #
      # ==== Examples
      #
      #   url(:show, :id => 1)
      #   url(:show, 1)
      #   url(:show, :name => :test)
      #   url("/show/:id/:name", :id => 1, :name => foo)
      #
      def url(*args)
        params = args.extract_options!  # parameters is hash at end
        names, params_array = args.partition{|a| a.is_a?(Symbol)}
        name = names.join("_").to_sym    # route name is concatenated with underscores
        if params.is_a?(Hash)
          params[:format] = params[:format].to_s if params.has_key?(:format)
          params.each { |k,v| params[k] = v.to_param if v.respond_to?(:to_param) }
        end
        url = if params_array.empty?
          router.url(name, params)
        else
          router.url(name, *(params_array << params))
        end
        url[0,0] = conform_uri(uri_root) if defined?(uri_root)
        url[0,0] = conform_uri(ENV['RACK_BASE_URI']) if ENV['RACK_BASE_URI']
        url = "/" if url.blank?
        url
      rescue HttpRouter::UngeneratableRouteException
        route_error = "route mapping for url(#{name.inspect}) could not be found!"
        raise Padrino::Routing::UnrecognizedException.new(route_error)
      end
      alias :url_for :url

      private

        # Add prefix slash if its not present and remove trailing slashes.
        def conform_uri(uri_string)
          uri_string.gsub(/^(?!\/)(.*)/, '/\1').gsub(/[\/]+$/, '')
        end

        ##
        # Rewrite default because now routes can be:
        #
        # ==== Examples
        #
        #   get :index                                    # => "/"
        #   get :index, :map => "/"                       # => "/"
        #   get :show,  :map => "/show-me"                # => "/show-me"
        #   get "/foo/bar"                                # => "/show"
        #   get :index, :parent => :user                  # => "/user/:user_id/index"
        #   get :show, :with => :id, :parent => :user     # => "/user/:user_id/show/:id"
        #   get :show, :with => :id                       # => "/show/:id"
        #   get :show, :with => [:id, :name]              # => "/show/:id/:name"
        #   get :list, :provides => :js                   # => "/list.{:format,js)"
        #   get :list, :provides => :any                  # => "/list(.:format)"
        #   get :list, :provides => [:js, :json]          # => "/list.{!format,js|json}"
        #   get :list, :provides => [:html, :js, :json]   # => "/list(.{!format,js|json})"
        #
        def route(verb, path, options={}, &block)
          # Do padrino parsing. We dup options so we can build HEAD request correctly
          route_options = options.dup
          route_options[:provides] = @_provides if @_provides
          path, name, options = *parse_route(path, route_options, verb)

          # Sinatra defaults
          define_method "#{verb} #{path}", &block
          unbound_method = instance_method("#{verb} #{path}")
          block =
            if block.arity != 0
              proc { unbound_method.bind(self).call(*@block_params) }
            else
              proc { unbound_method.bind(self).call }
            end
          invoke_hook(:route_added, verb, path, block)

          # HTTPRouter route construction
          route = router.add(path)
          route.name(name) if name
          route.send(verb.downcase.to_sym)
          route.host(options.delete(:host)) if options.key?(:host)
          route.default_values = options.delete(:default_values)

          route.to(block)

          # Add Sinatra conditions
          options.each { |option, args| send(option, *args) }
          conditions, @conditions = @conditions, []
          route.custom_conditions = conditions

          # Add Application defaults
          if @_controller
            route.before_filters = @before_filters
            route.after_filters  = @after_filters
            route.use_layout     = @layout
            route.controller     = Array(@_controller).first.to_s
          else
            route.before_filters = []
            route.after_filters  = []
          end

          route
        end

        ##
        # Returns the final parsed route details (modified to reflect all Padrino options)
        # given the raw route. Raw route passed in could be a named alias or a string and
        # is parsed to reflect provides formats, controllers, parents, 'with' parameters,
        # and other options.
        #
        def parse_route(path, options, verb)
          # We need save our originals path/options so we can perform correctly cache.
          original = [path, options.dup]

          # We need check if path is a symbol, if that it's a named route
          map = options.delete(:map)

          if path.kind_of?(Symbol) # path i.e :index or :show
            name = path                       # The route name
            path = map || path.to_s           # The route path
          end

          if path.kind_of?(String) # path i.e "/index" or "/show"
            # Backwards compatability

            if path == '(/)'
              path = '/'
              warn "WARNING! #{Padrino.first_caller}: #{verb} (/) is deprecated, simply use / instead" if verb != "HEAD"
            end

            if path =~ /\(\/\)$/
              path.gsub(/\(\/\)$/, '/?')
              warn "WARNING! #{Padrino.first_caller}: #{verb} (/) is deprecated, simply use /? instead" if verb != "HEAD"
            end

            # Now we need to parse our 'with' params
            if with_params = options.delete(:with)
              path = process_path_for_with_params(path, with_params)
            end

            # Now we need to parse our provides
            options.delete(:provides) if options[:provides].nil?

            if format_params = options[:provides]
              process_path_for_provides(path, format_params)
            end

            # Build our controller
            controller = Array(@_controller).collect { |c| c.to_s }

            unless controller.empty?
              # Now we need to add our controller path only if not mapped directly
              if map.blank?
                controller_path = controller.join("/")
                path.gsub!(%r{^\(/\)|/\?}, "")
                path = File.join(controller_path, path)
              end
              # Here we build the correct name route
              if name
                controller_name = controller.join("_")
                name = "#{controller_name}_#{name}".to_sym unless controller_name.blank?
              end
            end

            # Now we need to parse our 'parent' params and parent scope
            if parent_params = options.delete(:parent) || @_parents
              parent_params = Array(@_parents) + Array(parent_params)
              path = process_path_for_parent_params(path, parent_params)
            end

            # Small reformats
            path.gsub!(%r{/?index/?}, '')                  # Remove index path
            path[0,0] = "/" if path !~ %r{^\(?/} && path   # Paths must start with a /
            path.sub!(%r{/$}, '') if path != "/"           # Remove latest trailing delimiter
          end

          # Merge in option defaults
          options.reverse_merge!(:default_values => @_defaults)

          [path, name, options]
        end

        ##
        # Processes the existing path and appends the 'with' parameters onto the route
        # Used for calculating path in route method
        #
        def process_path_for_with_params(path, with_params)
          File.join(path, Array(with_params).collect(&:inspect).join("/"))
        end

        ##
        # Processes the existing path and prepends the 'parent' parameters onto the route
        # Used for calculating path in route method
        #
        def process_path_for_parent_params(path, parent_params)
          parent_prefix = parent_params.uniq.collect { |param| "#{param}/:#{param}_id" }.join("/")
          File.join(parent_prefix, path)
        end

        ##
        # Processes the existing path and appends the 'format' suffix onto the route
        # Used for calculating path in route method
        #
        def process_path_for_provides(path, format_params)
          path << "(.:format)" unless path[-10, 10] == '(.:format)'
        end

        ##
        # Allow paths for the given request head or request format
        #
        def provides(*types)
          condition do
            mime_types        = types.map { |t| mime_type(t) }
            accepts           = request.accept.map { |a| a.split(";")[0].strip }
            matching_types    = (accepts & mime_types)
            request.path_info =~ /\.([^\.\/]+)$/
            url_format        = $1.to_sym if $1

            if !url_format && matching_types.first
              type = Rack::Mime::MIME_TYPES.find { |k, v| v == matching_types.first }[0].sub(/\./,'').to_sym
              accept_format = CONTENT_TYPE_ALIASES[type] || type
            end

            matched_format = types.include?(:any)            ||
                             types.include?(accept_format)   ||
                             types.include?(url_format)      ||
                             accepts.any? { |a| a == "*/*" } ||
                             ((!url_format) && request.accept.empty? && types.include?(:html))

            if matched_format
              @_content_type = url_format || accept_format || :html
              content_type(@_content_type, :charset => 'utf-8')
            end

            matched_format
          end
        end
    end

    module InstanceMethods
      ##
      # Instance method for url generation like:
      #
      # ==== Examples
      #
      #   url(:show, :id => 1)
      #   url(:show, :name => :test)
      #   url("/show/:id/:name", :id => 1, :name => foo)
      #
      def url(*args)
        self.class.url(*args)
      end
      alias :url_for :url

      ##
      # This is mostly just a helper so request.path_info isn't changed when
      # serving files from the public directory
      #
      def static_file?(path_info)
        return if (public_dir = settings.public).nil?
        public_dir = File.expand_path(public_dir)

        path = File.expand_path(public_dir + unescape(path_info))
        return if path[0, public_dir.length] != public_dir
        return unless File.file?(path)
        return path
      end

      ##
      # Method for deliver static files.
      #
      def static!
        if path = static_file?(request.path_info)
          env['sinatra.static_file'] = path
          send_file(path, :disposition => nil)
        end
      end

      ##
      # Return the request format, this is useful when we need to respond to a given content_type like:
      #
      # ==== Examples
      #
      #   get :index, :provides => :any do
      #     case content_type
      #       when :js    then ...
      #       when :json  then ...
      #       when :html  then ...
      #     end
      #   end
      #
      def content_type(type=nil, params={})
        type.nil? ? @_content_type : super(type, params)
      end

      private
        ##
        # Compatibility with http_router
        #
        def route!(base=self.class, pass_block=nil)
          if base.router and match = base.router.recognize(@request)
            if !match.matched?
              route_eval {
                match.headers.each{|k,v| response[k] = v}
                status match.status
              }
            elsif match
              @block_params = match.params
              (@params ||= {}).merge!(match.params_as_hash)
              pass_block = catch(:pass) do
                # Run Sinatra Conditions
                match.path.route.custom_conditions.each { |cond| throw :pass if instance_eval(&cond) == false }
                # Run scoped before filters
                match.path.route.before_filters.each { |bef| throw :pass if instance_eval(&bef) == false }
                # If present set current controller layout
                parent_layout = base.instance_variable_get(:@layout)
                base.instance_variable_set(:@layout, match.path.route.use_layout) if match.path.route.use_layout
                # Provide access to the current controller to the request
                request.match = match
                # Now we can eval route, but because we have "throw halt" we need to be
                # (en)sure to reset old layout and run controller after filters.
                begin
                  route_eval(&match.destination)
                ensure
                  base.instance_variable_set(:@layout, parent_layout) if match.path.route.use_layout
                  match.path.route.after_filters.each { |aft| throw :pass if instance_eval(&aft) == false }
                end
              end
            end
          end

          # Run routes defined in superclass.
          if base.superclass.respond_to?(:router)
            route! base.superclass, pass_block
            return
          end

          route_eval(&pass_block) if pass_block

          route_missing
        end
    end # InstanceMethods
  end # Routing
end # Padrino