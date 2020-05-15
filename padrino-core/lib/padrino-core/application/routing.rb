require 'padrino-support'
require 'padrino-core/path_router' unless defined?(PathRouter)
require 'padrino-core/ext/sinatra'
require 'padrino-core/filter'

module Padrino
  ##
  # Padrino provides advanced routing definition support to make routes and
  # url generation much easier. This routing system supports named route
  # aliases and easy access to url paths. The benefits of this is that instead
  # of having to hard-code route urls into every area of your application, now
  # we can just define the urls in a single spot and then attach an alias
  # which can be used to refer to the url throughout the application.
  #
  module Routing
    # Defines common content-type alias mappings.
    CONTENT_TYPE_ALIASES = { :htm => :html } unless defined?(CONTENT_TYPE_ALIASES)
    # Defines the available route priorities supporting route deferrals.
    ROUTE_PRIORITY = {:high => 0, :normal => 1, :low => 2} unless defined?(ROUTE_PRIORITY)

    # Raised when a route was invalid or cannot be processed.
    class UnrecognizedException < RuntimeError; end

    # Raised when block arity was nonzero and was not same with
    # captured parameter length.
    class BlockArityError < ArgumentError
      def initialize(path, block_arity, required_arity)
        super "route block arity does not match path '#{path}' (#{block_arity} for #{required_arity})"
      end
    end

    class Parent < String
      attr_reader :map
      attr_reader :optional
      attr_reader :options

      alias_method :optional?, :optional

      def initialize(value, options={})
        super(value.to_s)
        @map      = options.delete(:map)
        @optional = options.delete(:optional)
        @options  = options
      end
    end

    class << self
      ##
      # Main class that register this extension.
      #
      def registered(app)
        app.send(:include, InstanceMethods)
        app.extend(ClassMethods)
      end
      alias :included :registered
    end

    # Class methods responsible for enhanced routing for controllers.
    module ClassMethods
      ##
      # Method to organize our routes in a better way.
      #
      # @param [Array] args
      #   Controller arguments.
      #
      # @yield []
      #   The given block will be used to define the routes within the
      #   Controller.
      #
      # @example
      #   controller :admin do
      #     get :index do; ...; end
      #     get :show, :with => :id  do; ...; end
      #   end
      #
      #   url(:admin_index) # => "/admin"
      #   url(:admin_show, :id => 1) # "/admin/show/1"
      #
      # @example Using named routes follow the sinatra way:
      #   controller "/admin" do
      #     get "/index" do; ...; end
      #     get "/show/:id" do; ...; end
      #   end
      #
      # @example Supply +:provides+ to all controller routes:
      #   controller :provides => [:html, :xml, :json] do
      #     get :index do; "respond to html, xml and json"; end
      #     post :index do; "respond to html, xml and json"; end
      #     get :foo do; "respond to html, xml and json"; end
      #   end
      #
      # @example Specify parent resources in padrino with the +:parent+ option on the controller:
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
      # @example Specify conditions to run for all routes:
      #   controller :conditions => {:protect => true} do
      #     def self.protect(protected)
      #       condition do
      #         halt 403, "No secrets for you!" unless params[:key] == "s3cr3t"
      #       end if protected
      #     end
      #
      #     # This route will only return "secret stuff" if the user goes to
      #     # `/private?key=s3cr3t`.
      #     get("/private") { "secret stuff" }
      #
      #     # And this one, too!
      #     get("/also-private") { "secret stuff" }
      #
      #     # But you can override the conditions for each route as needed.
      #     # This route will be publicly accessible without providing the
      #     # secret key.
      #     get :index, :protect => false do
      #       "Welcome!"
      #     end
      #   end
      #
      # @example Supply default values:
      #   controller :lang => :de do
      #     get :index, :map => "/:lang" do; "params[:lang] == :de"; end
      #   end
      #
      # In a controller, before and after filters are scoped and don't
      #   affect other controllers or the main app.
      # In a controller, layouts are scoped and don't affect other
      #   controllers or the main app.
      #
      # @example
      #   controller :posts do
      #     layout :post
      #     before { foo }
      #     after  { bar }
      #   end
      #
      def controller(*args, &block)
        if block_given?
          with_new_options(*args) { instance_eval(&block) }
        else
          include(*args) if extensions.any?
        end
      end
      alias :controllers :controller

      ##
      # Add a before filter hook.
      #
      # @see #construct_filter
      #
      def before(*args, &block)
        add_filter :before, &(args.empty? ? block : construct_filter(*args, &block))
      end

      ##
      # Add an after filter hook.
      #
      # @see #construct_filter
      #
      def after(*args, &block)
        add_filter :after, &(args.empty? ? block : construct_filter(*args, &block))
      end

      ##
      # Adds a filter hook to a request.
      #
      def add_filter(type, &block)
        filters[type] << block
      end

      ##
      # Creates a filter to process before/after the matching route.
      #
      # @param [Array] args
      #
      # @example We are be able to filter with String path
      #   before('/') { 'only to :index' }
      #   get(:index} { 'foo' } # => filter match only before this.
      #   get(:main) { 'bar' }
      #
      # @example is the same of
      #   before(:index) { 'only to :index' }
      #   get(:index} { 'foo' } # => filter match only before this.
      #   get(:main) { 'bar' }
      #
      # @example it works only for the given controller
      #   controller :foo do
      #     before(:index) { 'only to for :foo_index' }
      #     get(:index} { 'foo' } # => filter match only before this.
      #     get(:main) { 'bar' }
      #   end
      #
      #   controller :bar do
      #     before(:index) { 'only to for :bar_index' }
      #     get(:index} { 'foo' } # => filter match only before this.
      #     get(:main) { 'bar' }
      #   end
      #
      # @example if filters based on a symbol or regexp
      #   before :index, /main/ do; ... end
      #   # => match only path that are  +/+ or contains +main+
      #
      # @example filtering everything except an occurrence
      #   before :except => :index do; ...; end
      #
      # @example you can also filter using a request param
      #   before :agent => /IE/ do; ...; end
      #   # => match +HTTP_USER_AGENT+ containing +IE+
      #
      # @see http://padrinorb.com/guides/controllers/route-filters/
      #
      def construct_filter(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        if except = options.delete(:except)
          fail "You cannot use :except with other options specified" unless args.empty? && options.empty?
          except = Array(except)
          options = except.last.is_a?(Hash) ? except.pop : {}
        end
        Filter.new(!except, @_controller, options, Array(except || args), &block)
      end

      ##
      # Provides many parents with shallowing.
      #
      # @param [Symbol] name
      #   The parent name.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @example
      #   controllers :product do
      #     parent :shop, :optional => true, :map => "/my/stand"
      #     parent :category, :optional => true
      #     get :show, :with => :id do
      #       # generated urls:
      #       #   "/product/show/#{params[:id]}"
      #       #   "/my/stand/#{params[:shop_id]}/product/show/#{params[:id]}"
      #       #   "/my/stand/#{params[:shop_id]}/category/#{params[:category_id]}/product/show/#{params[:id]}"
      #       # url_for(:product, :show, :id => 10) => "/product/show/10"
      #       # url_for(:product, :show, :shop_id => 5, :id => 10) => "/my/stand/5/product/show/10"
      #       # url_for(:product, :show, :shop_id => 5, :category_id => 1, :id => 10) => "/my/stand/5/category/1/product/show/10"
      #     end
      #   end
      #
      def parent(name = nil, options={})
        return super() unless name
        defaults = { :optional => false, :map => name.to_s }
        options = defaults.merge(options)
        @_parent = Array(@_parent) unless @_parent.is_a?(Array)
        @_parent << Parent.new(name, options)
      end

      ##
      # Using PathRouter, for features and configurations.
      #
      # @example
      #   router.add('/greedy/:greed')
      #   router.recognize('/simple')
      #
      def router
        @router ||= PathRouter.new
        block_given? ? yield(@router) : @router
      end
      alias :urls :router

      def compiled_router
        if @deferred_routes
          deferred_routes.each do |routes|
            routes.each do |(route, dest)|
              route.to(&dest)
              route.before_filters.flatten!
              route.after_filters.flatten!
            end
          end
          @deferred_routes = nil
        end
        router
      end

      def deferred_routes
        @deferred_routes ||= ROUTE_PRIORITY.map{[]}
      end

      def reset_router!
        @deferred_routes = nil
        router.reset!
      end

      ##
      # Recognize a given path.
      #
      # @param [String] path
      #   Path+Query to parse
      #
      # @return [Symbol, Hash]
      #   Returns controller and query params.
      #
      # @example Giving a controller like:
      #   controller :foo do
      #     get :bar, :map => 'foo-bar-:id'; ...; end
      #   end
      #
      # @example You should be able to reverse:
      #   MyApp.url(:foo_bar, :id => :mine)
      #   # => /foo-bar-mine
      #
      # @example Into this:
      #   MyApp.recognize_path('foo-bar-mine')
      #   # => [:foo_bar, :id => :mine]
      #
      def recognize_path(path)
        responses = @router.recognize_path(path)
        [responses[0], responses[1]]
      end

      ##
      # Instance method for url generation.
      #
      # @option options [String] :fragment
      #   An addition to url to identify a portion of requested resource (i.e #something).
      # @option options [String] :anchor
      #   Synonym for fragment.
      #
      # @example
      #   url(:show, :id => 1)
      #   url(:show, :name => 'test', :id => 24)
      #   url(:show, 1)
      #   url(:controller_name, :show, :id => 21)
      #   url(:controller_show, :id => 29)
      #   url(:index, :fragment => 'comments')
      #
      def url(*args)
        params = args.last.is_a?(Hash) ? args.pop : {}
        fragment = params.delete(:fragment) || params.delete(:anchor)
        path = make_path_with_params(args, value_to_param(params))
        rebase_url(fragment ? path << '#' << fragment.to_s : path)
      end
      alias :url_for :url

      ##
      # Returns absolute url. By default adds 'http://localhost' before generated url.
      # To change that `set :base_url, 'http://example.com'` in your app.
      #
      def absolute_url(*args)
        base_url + url(*args)
      end

      def get(path, *args, &block)
        conditions = @conditions.dup
        route('GET', path, *args, &block)

        @conditions = conditions
        route('HEAD', path, *args, &block)
      end

      def put(path, *args, &block)     route 'PUT',     path, *args, &block end
      def post(path, *args, &block)    route 'POST',    path, *args, &block end
      def delete(path, *args, &block)  route 'DELETE',  path, *args, &block end
      def head(path, *args, &block)    route 'HEAD',    path, *args, &block end
      def options(path, *args, &block) route 'OPTIONS', path, *args, &block end
      def patch(path, *args, &block)   route 'PATCH',   path, *args, &block end
      def link(path, *args, &block)    route 'LINK',    path, *args, &block end
      def unlink(path, *args, &block)  route 'UNLINK',  path, *args, &block end

      def rebase_url(url)
        if url.start_with?('/')
          new_url = ''
          new_url << conform_uri(ENV['RACK_BASE_URI']) if ENV['RACK_BASE_URI']
          new_url << conform_uri(uri_root) if defined?(uri_root)
          new_url << url
        else
          url.empty? ? '/' : url
        end
      end

      ##
      # Processes the existing path and prepends the 'parent' parameters onto the route
      # Used for calculating path in route method.
      #
      def process_path_for_parent_params(path, parent_params)
        parent_prefix = parent_params.flatten.compact.uniq.map do |param|
          map  = (param.respond_to?(:map) && param.map ? param.map : param.to_s)
          part = "#{map}/:#{Inflections.singularize(param)}_id/"
          part = "(#{part})?" if param.respond_to?(:optional) && param.optional?
          part
        end

        [parent_prefix, path].flatten.join("")
      end

      private

      # temporary variables named @_parent, @_provides, @_use_format, @_cache, @_expires, @_map, @_conditions, @_accepts, @_params
      CONTROLLER_OPTIONS = [ :parent, :provides, :use_format, :cache, :expires, :map, :conditions, :accepts, :params ].freeze

      # Saves controller options, yields the block, restores controller options.
      def with_new_options(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}

        CONTROLLER_OPTIONS.each{ |key| replace_instance_variable("@_#{key}", options.delete(key)) }
        replace_instance_variable(:@_controller, args)
        replace_instance_variable(:@_defaults, options)
        replace_instance_variable(:@filters, :before => @filters[:before].dup, :after => @filters[:after].dup)
        replace_instance_variable(:@layout, @layout)

        yield

        @original_instance.each do |key, value|
          instance_variable_set(key, value)
        end
      end

      # Sets instance variable by name and saves the original value in @original_instance hash
      def replace_instance_variable(name, value)
        @original_instance ||= {}
        @original_instance[name] = instance_variable_get(name)
        instance_variable_set(name, value)
      end

      # Searches compiled router for a path responding to args and makes a path with params.
      def make_path_with_params(args, params)
        names, params_array = args.partition{ |arg| arg.is_a?(Symbol) }
        name = names[0, 2].join(" ").to_sym
        compiled_router.path(name, *(params_array << params))
      rescue PathRouter::InvalidRouteException
        raise Padrino::Routing::UnrecognizedException, "Route mapping for url(#{name.inspect}) could not be found"
      end

      # Parse params from the url method
      def value_to_param(object)
        case object
        when Array
          object.map { |item| value_to_param(item) }.compact
        when Hash
          object.inject({}) do |all, (key, value)|
            next all if value.nil?
            all[key] = value_to_param(value)
            all
          end
        when nil
        else
          object.respond_to?(:to_param) ? object.to_param : object
        end
      end

      # Add prefix slash if its not present and remove trailing slashes.
      def conform_uri(uri_string)
        uri_string.gsub(/^(?!\/)(.*)/, '/\1').gsub(/[\/]+$/, '')
      end

      ##
      # Rewrite default routes.
      #
      # @example
      #   get :index                                             # => "/"
      #   get :index, "/"                                        # => "/"
      #   get :index, :map => "/"                                # => "/"
      #   get :show, "/show-me"                                  # => "/show-me"
      #   get :show,  :map => "/show-me"                         # => "/show-me"
      #   get "/foo/bar"                                         # => "/show"
      #   get :index, :parent => :user                           # => "/user/:user_id/index"
      #   get :show, :with => :id, :parent => :user              # => "/user/:user_id/show/:id"
      #   get :show, :with => :id                                # => "/show/:id"
      #   get [:show, :id]                                       # => "/show/:id"
      #   get :show, :with => [:id, :name]                       # => "/show/:id/:name"
      #   get [:show, :id, :name]                                # => "/show/:id/:name"
      #   get :list, :provides => :js                            # => "/list.{:format,js)"
      #   get :list, :provides => :any                           # => "/list(.:format)"
      #   get :list, :provides => [:js, :json]                   # => "/list.{!format,js|json}"
      #   get :list, :provides => [:html, :js, :json]            # => "/list(.{!format,js|json})"
      #   get :list, :priority => :low                           # Defers route to be last
      #   get /pattern/, :name => :foo, :generate_with => '/foo' # Generates :foo as /foo
      def route(verb, path, *args, &block)
        options = case args.size
          when 2
            args.last.merge(:map => args.first)
          when 1
            map = args.shift if args.first.is_a?(String)
            if args.first.is_a?(Hash)
              map ? args.first.merge(:map => map) : args.first
            else
              {:map => map || args.first}
            end
          when 0
            {}
          else raise
        end

        route_options = options.dup
        route_options[:provides] = @_provides if @_provides
        route_options[:accepts]  = @_accepts if @_accepts
        route_options[:params] = @_params unless @_params.nil? || route_options.include?(:params)

        # Add Sinatra condition to check rack-protection failure.
        if respond_to?(:protect_from_csrf) && protect_from_csrf && (report_csrf_failure || allow_disabled_csrf)
          unless route_options.has_key?(:csrf_protection)
            route_options[:csrf_protection] = true
          end
        end

        path, *route_options[:with] = path if path.is_a?(Array)
        action = path
        path, name, route_parents, options, route_options = *parse_route(path, route_options, verb)
        options = @_conditions.merge(options) if @_conditions

        method_name = "#{verb} #{path}"
        unbound_method = generate_method(method_name.to_sym, &block)

        block_arity = block.arity
        block = if block_arity == 0
                  proc{ |request, _| unbound_method.bind(request).call }
                else
                  proc{ |request, block_params| unbound_method.bind(request).call(*block_params) }
                end

        invoke_hook(:route_added, verb, path, block)

        path[0, 0] = "/" if path == "(.:format)?"
        route = router.add(verb, path, route_options)
        route.name = name if name
        route.action = action
        priority_name = options.delete(:priority) || :normal
        priority = ROUTE_PRIORITY[priority_name] or raise("Priority #{priority_name} not recognized, try #{ROUTE_PRIORITY.keys.join(', ')}")
        route.cache = options.key?(:cache) ? options.delete(:cache) : @_cache
        route.cache_expires = options.key?(:expires) ? options.delete(:expires) : @_expires
        route.parent = route_parents ? (route_parents.count == 1 ? route_parents.first : route_parents) : route_parents
        route.host = options.delete(:host) if options.key?(:host)
        route.user_agent = options.delete(:agent) if options.key?(:agent)
        if options.key?(:default_values)
          defaults = options.delete(:default_values)
          #route.options[:default_values] = defaults if defaults
          route.default_values = defaults if defaults
        end
        options.delete_if do |option, captures|
          if route.significant_variable_names.include?(option.to_s)
            route.capture[option] = Array(captures).first
            true
          end
        end

        # Add Sinatra conditions.
        options.each do |option, _args|
          option = :provides_format if option == :provides
          route.respond_to?(option) ? route.send(option, *_args) : send(option, *_args)
        end
        conditions, @conditions = @conditions, []
        route.custom_conditions.concat(conditions)

        invoke_hook(:padrino_route_added, route, verb, path, args, options, block)

        block_parameter_length = route.block_parameter_length
        if block_arity > 0 && block_parameter_length != block_arity
          fail BlockArityError.new(route.path, block_arity, block_parameter_length)
        end

        # Add Application defaults.
        route.before_filters << @filters[:before]
        route.after_filters << @filters[:after]
        if @_controller
          route.use_layout = @layout
          route.controller = Array(@_controller).join('/')
        end

        deferred_routes[priority] << [route, block]

        route
      end

      ##
      # Returns the final parsed route details (modified to reflect all
      # Padrino options) given the raw route. Raw route passed in could be
      # a named alias or a string and is parsed to reflect provides formats,
      # controllers, parents, 'with' parameters, and other options.
      #
      def parse_route(path, options, verb)
        path = path.dup if path.kind_of?(String)
        route_options = {}

        if options[:params] == true
          options.delete(:params)
        elsif options.include?(:params)
          options[:params] ||= []
          options[:params] |= Array(options[:with]) if options[:with]
        end

        # We need check if path is a symbol, if that it's a named route.
        map = options.delete(:map)

        # path i.e :index or :show
        if path.kind_of?(Symbol)
          name = path
          path = map ? map.dup : (path == :index ? '/' : path.to_s)
        end

        # Build our controller
        controller = Array(@_controller).map(&:to_s)

        case path
        when String # path i.e "/index" or "/show"
          # Now we need to parse our 'with' params
          if with_params = options.delete(:with)
            path = process_path_for_with_params(path, with_params)
          end

          # Now we need to parse our provides
          options.delete(:provides) if options[:provides].nil?
        
          options.delete(:accepts) if options[:accepts].nil?

          if @_use_format || options[:provides]
            process_path_for_provides(path)
            # options[:add_match_with] ||= {}
            # options[:add_match_with][:format] = /[^\.]+/
          end

          absolute_map = map && map[0] == ?/

          unless controller.empty?
            # Now we need to add our controller path only if not mapped directly
            if !map && !absolute_map
              controller_path = controller.join("/")
              path.gsub!(%r{^\(/\)|/\?}, "")
              path = File.join(controller_path, path)  unless @_map
            end
          end

          # Now we need to parse our 'parent' params and parent scope.
          if !absolute_map and parent_params = options.delete(:parent) || @_parent
            parent_params = (Array(@_parent) + Array(parent_params)).uniq
            path = process_path_for_parent_params(path, parent_params)
          end

          # Add any controller level map to the front of the path.
          path = "#{@_map}/#{path}".squeeze('/') unless absolute_map || !@_map

          # Small reformats
          path.gsub!(%r{/\?$}, '(/)')                  # Remove index path
          path.gsub!(%r{//$}, '/')                     # Remove index path
          path[0,0] = "/" if path !~ %r{^\(?/}         # Paths must start with a /
          path.sub!(%r{/(\))?$}, '\\1') if path != "/" # Remove latest trailing delimiter
          path.gsub!(/\/(\(\.|$)/, '\\1')              # Remove trailing slashes
          path.squeeze!('/')
        when Regexp
          route_options[:path_for_generation] = options.delete(:generate_with) if options.key?(:generate_with)
        end

        name = options.delete(:route_name) if name.nil? && options.key?(:route_name)
        name = options.delete(:name) if name.nil? && options.key?(:name)
        if name
          controller_name = controller.join("_")
          name = "#{controller_name} #{name}".to_sym unless controller_name.empty?
        end

        options[:default_values] = @_defaults unless options.has_key?(:default_values)

        [path, name, parent_params, options, route_options]
      end

      ##
      # Processes the existing path and appends the 'with' parameters onto the route
      # Used for calculating path in route method.
      #
      def process_path_for_with_params(path, with_params)
        File.join(path, Array(with_params).map do |step|
          step.kind_of?(String) ? step : step.inspect
        end.join("/"))
      end

      ##
      # Processes the existing path and appends the 'format' suffix onto the route.
      # Used for calculating path in route method.
      #
      def process_path_for_provides(path)
        path << "(.:format)?" unless path[-11, 11] == '(.:format)?'
      end

      ##
      # Allows routing by MIME-types specified in the URL or ACCEPT header.
      #
      # By default, if a non-provided mime-type is specified in a URL, the
      # route will not match an thus return a 404.
      #
      # Setting the :treat_format_as_accept option to true allows treating
      # missing mime types specified in the URL as if they were specified
      # in the ACCEPT header and thus return 406.
      #
      # If no type is specified, the first in the provides-list will be
      # returned.
      #
      # @example
      #   get "/a", :provides => [:html, :js]
      #   # => GET /a      => :html
      #   # => GET /a.js   => :js
      #   # => GET /a.xml  => 404
      #
      #   get "/b", :provides => [:html]
      #   # => GET /b; ACCEPT: html => html
      #   # => GET /b; ACCEPT: js   => 406
      #
      #   enable :treat_format_as_accept
      #   get "/c", :provides => [:html, :js]
      #   # => GET /c.xml => 406
      #
      def provides(*types)
        @_use_format = true
        provides_format(*types)
      end

      def provides_format(*types)
        mime_types = types.map{ |type| mime_type(CONTENT_TYPE_ALIASES[type] || type) }
        condition do
          return provides_format?(types, params[:format].to_sym) if params[:format]

          accepts = request.accept.map(&:to_str)
          # Per rfc2616-sec14:
          # Assume */* if no ACCEPT header is given.
          catch_all = accepts.delete("*/*")

          return provides_any?(accepts) if types.include?(:any)

          accepts = accepts.empty? ? mime_types.slice(0,1) : (accepts & mime_types)

          type = accepts.first && mime_symbol(accepts.first)
          type ||= catch_all && types.first

          accept_format = CONTENT_TYPE_ALIASES[type] || type
          if types.include?(accept_format)
            content_type(accept_format || :html)
          else
            catch_all ? true : halt(406)
          end
        end
      end

      ##
      # Allows routing by Media type.
      #
      # @example
      #   get "/a", :accepts => [:html, :js]
      #   # => GET /a CONTENT_TYPE text/html => :html
      #   # => GET /a CONTENT_TYPE application/javascript => :js
      #   # => GET /a CONTENT_TYPE application/xml => 406
      #
      def accepts(*types)
        mime_types = types.map{ |type| mime_type(CONTENT_TYPE_ALIASES[type] || type) }
        condition do
          halt 406 unless mime_types.include?(request.media_type)
          content_type(mime_symbol(request.media_type))
        end
      end

      ##
      # Implements checking for rack-protection failure flag when
      # `report_csrf_failure` is enabled.
      #
      # @example
      #   post("/", :csrf_protection => false)
      #
      def csrf_protection(enabled)
        return unless enabled
        condition do
          if request.env['protection.csrf.failed']
            message = settings.protect_from_csrf.kind_of?(Hash) && settings.protect_from_csrf[:message] || 'Forbidden'
            halt(403, message)
          end
        end
      end
    end

    ##
    # Instance methods related to recognizing and processing routes and serving static files.
    #
    module InstanceMethods
      ##
      # Instance method for URL generation.
      #
      # @example
      #   url(:show, :id => 1)
      #   url(:show, :name => :test)
      #   url(:show, 1)
      #   url("/foo", false, false)
      #
      # @see Padrino::Routing::ClassMethods#url
      #
      def url(*args)
        if args.first.is_a?(String)
          url_path = settings.rebase_url(args.shift)
          if args.empty?
            url_path
          else
            # Delegate sinatra-style urls to Sinatra. Ex: url("/foo", false, false)
            # http://www.sinatrarb.com/intro#Generating%20URLs
            super url_path, *args
          end
        else
          # Delegate to Padrino named route URL generation.
          settings.url(*args)
        end
      end
      alias :url_for :url

      ##
      # Returns absolute url. Calls Sinatra::Helpers#uri to generate protocol version, hostname and port.
      #
      # @example
      #   absolute_url(:show, :id => 1)  # => http://example.com/show?id=1
      #   absolute_url(:show, 24)        # => https://example.com/admin/show/24
      #   absolute_url('/foo/bar')       # => https://example.com/admin/foo/bar
      #   absolute_url('baz')            # => https://example.com/admin/foo/baz
      #
      def absolute_url(*args)
        url_path = args.shift
        if url_path.is_a?(String) && !url_path.start_with?('/')
          url_path = request.env['PATH_INFO'].rpartition('/').first << '/' << url_path
        end
        uri url(url_path, *args), true, false
      end

      def recognize_path(path)
        settings.recognize_path(path)
      end

      ##
      # Returns the current path within a route from specified +path_params+.
      #
      def current_path(*path_params)
        if path_params.last.is_a?(Hash)
          path_params[-1] = params.merge(path_params[-1])
        else
          path_params << params
        end

        path_params[-1] = Utils.symbolize_keys(path_params[-1])
        @route.path(*path_params)
      end

      ##
      # Returns the current route
      #
      # @example
      #   -if route.controller == :press
      #     %li=show_article
      #
      def route
        @route
      end

      ##
      # This is mostly just a helper so request.path_info isn't changed when
      # serving files from the public directory.
      #
      def static_file?(path_info)
        return unless public_dir = settings.public_folder
        public_dir = File.expand_path(public_dir)
        path = File.expand_path(public_dir + unescape(path_info))
        return unless path.start_with?(public_dir)
        return unless File.file?(path)
        return path
      end

      #
      # Method for deliver static files.
      #
      def static!(options = {})
        if path = static_file?(request.path_info)
          env['sinatra.static_file'] = path
          cache_control(*settings.static_cache_control) if settings.static_cache_control?
          send_file(path, options)
        end
      end

      ##
      # Return the request format, this is useful when we need to respond to
      # a given Content-Type.
      #
      # @param [Symbol, nil] type
      #
      # @param [Hash] params
      #
      # @example
      #   get :index, :provides => :any do
      #     case content_type
      #       when :js    then ...
      #       when :json  then ...
      #       when :html  then ...
      #     end
      #   end
      #
      def content_type(type=nil, params={})
        return @_content_type unless type
        super(type, params)
        @_content_type = type
      end

      private

      def provides_any?(formats)
        accepted_format = formats.first
        type = accepted_format ? mime_symbol(accepted_format) : :html
        content_type(CONTENT_TYPE_ALIASES[type] || type)
      end

      def provides_format?(types, format)
        if ([:any, format] & types).empty?
          # Per rfc2616-sec14:
          # Answer with 406 if accept is given but types to not match any provided type.
          halt 406 if settings.respond_to?(:treat_format_as_accept) && settings.treat_format_as_accept
          false
        else
          content_type(format || :html)
        end
      end

      def mime_symbol(media_type)
        ::Rack::Mime::MIME_TYPES.key(media_type).sub(/\./,'').to_sym
      end

      def filter!(type, base=settings)
        filter! type, base.superclass if base.superclass.respond_to?(:filters)
        base.filters[type].each { |block| instance_eval(&block) }
      end

      def dispatch!
        @params = defined?(Sinatra::IndifferentHash) ? Sinatra::IndifferentHash[@request.params] : indifferent_params(@request.params)
        force_encoding(@params)
        invoke do
          static! if settings.static? && (request.get? || request.head?)
          route!
        end
      rescue ::Exception => boom
        filter! :before if boom.kind_of? ::Sinatra::NotFound
        invoke { @boom_handled = handle_exception!(boom) }
      ensure
        @boom_handled or begin
          filter! :after  unless env['sinatra.static_file']
        rescue ::Exception => boom
          invoke { handle_exception!(boom) } unless @env['sinatra.error']
        end
      end

      def route!(base = settings, pass_block = nil)
        Thread.current['padrino.instance'] = self
        first_time = true

        routes = base.compiled_router.call(@request) do |route, params|
          next if route.user_agent && !(route.user_agent =~ @request.user_agent)
          original_params, parent_layout = @params.dup, @layout
          returned_pass_block = invoke_route(route, params, first_time)
          pass_block = returned_pass_block if returned_pass_block
          first_time = false if first_time
          @params, @layout = original_params, parent_layout
        end

        unless routes.empty?
          verb = request.request_method
          candidacies, allows = routes.partition{|route| route.verb == verb }
          if candidacies.empty?
            response["Allows"] = allows.map(&:verb).join(", ")
            halt 405
          end
        end

        if base.superclass.respond_to?(:router)
          route!(base.superclass, pass_block)
          return
        end

        route_eval(&pass_block) if pass_block
        route_missing
      end

      def invoke_route(route, params, first_time)
        @_response_buffer = nil
        @route = request.route_obj = route
        captured_params = captures_from_params(params)

        # Should not overwrite params by given query
        @params.merge!(params) do |key, original, newval|
          @route.significant_variable_names.include?(key) ? newval : original
        end unless params.empty?

        @params[:format] = params[:format] if params[:format]
        @params[:captures] = captured_params if !captured_params.empty? && route.path.is_a?(Regexp)

        filter! :before if first_time

        catch(:pass) do
          begin
              (route.before_filters - settings.filters[:before]).each{|block| instance_eval(&block) }
              @layout = route.use_layout if route.use_layout
              route.custom_conditions.each {|block| pass if block.bind(self).call == false }
              route_response = route.block[self, captured_params]
              @_response_buffer = route_response.instance_of?(Array) ? route_response.last : route_response
              halt(route_response)
          ensure
            (route.after_filters - settings.filters[:after]).each {|block| instance_eval(&block) }
          end
        end
      end

      def captures_from_params(params)
        if params[:captures].instance_of?(Array) && !params[:captures].empty?
          params.delete(:captures)
        else
          params.values_at(*route.matcher.names).flatten
        end
      end
    end
  end
end
