$:.unshift '/Users/joshbuddy/Development/http_router/lib'

require 'http_router' unless defined?(HttpRouter)
require 'padrino-core/support_lite' unless defined?(SupportLite)

class Sinatra::Request #:nodoc:
  attr_accessor :route_obj

  def controller
    route_obj && route_obj.controller
  end
end

class HttpRouter #:nodoc:
  attr_accessor :runner
  class Route #:nodoc:
    attr_reader :before_filters, :after_filters
    attr_accessor :custom_conditions, :use_layout, :controller, :cache

    def add_before_filter(filter)
      @before_filters ||= []
      @before_filters << filter
    end

    def add_after_filter(filter)
      @after_filters ||= []
      @after_filters << filter
    end

    def before_filters=(filters)
      filters.each { |filter| add_before_filter(filter) } if filters
    end

    def after_filters=(filters)
      filters.each { |filter| add_after_filter(filter) } if filters
    end

    def custom_conditions=(custom_conditions)
      custom_conditions.each { |blk| arbitrary { |req, params| router.runner.instance_eval(&blk) != false } } if custom_conditions
      @custom_conditions = custom_conditions
    end
  end
end

module Padrino
  ##
  # Padrino provides advanced routing definition support to make routes and url generation much easier.
  # This routing system supports named route aliases and easy access to url paths.
  # The benefits of this is that instead of having to hard-code route urls into every area of your application,
  # now we can just define the urls in a single spot and then attach an alias which can be used to refer
  # to the url throughout the application.
  #
  module Routing
    CONTENT_TYPE_ALIASES = { :htm => :html } unless defined?(CONTENT_TYPE_ALIASES)

    class UnrecognizedException < RuntimeError #:nodoc:
    end

    ##
    # Keeps information about parent scope.
    #
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
          @_use_format, original_use_format = options.delete(:use_format), @_use_format
          @_cache,      original_cache      = options.delete(:cache), @_cache
          @_map,        original_map        = options.delete(:map), @_map
          @_defaults,   original_defaults   = options, @_defaults

          # Application defaults
          @filters,     original_filters = { :before => [], :after => [] }, @filters
          @layout,      original_layout         = nil, @layout

          instance_eval(&block)

          # Application defaults
          @filters        = original_filters
          @layout         = original_layout

          # Controller defaults
          @_controller, @_parents, @_cache = original_controller, original_parent, original_cache
          @_defaults, @_provides, @_map  = original_defaults, original_provides, original_map
          @_use_format = original_use_format
        else
          include(*args) if extensions.any?
        end
      end
      alias :controllers :controller

      ##
      # Provides many parents with shallowing.
      #
      # ==== Examples
      #
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
      def parent(name, options={})
        defaults = { :optional => false, :map => name.to_s }
        options = defaults.merge(options)
        @_parents = Array(@_parents) unless @_parents.is_a?(Array)
        @_parents << Parent.new(name, options)
      end

      ##
      # Using HTTPRouter, for features and configurations see: http://github.com/joshbuddy/http_router
      #
      # ==== Examples
      #
      #   router.add('/greedy/:greed')
      #   router.recognize('/simple')
      #
      def router
        @router ||= HttpRouter.new
        block_given? ? yield(@router) : @router
      end
      alias :urls :router

      def recognition_router
        @recognition_router ||= HttpRouter.new
      end

      def reset_router!
        router.reset!
        recognition_router.reset!
      end

      def recognize_path(path)
        if response = @recognition_router.recognize(Rack::MockRequest.env_for(path))
          [response.path.route.named, response.params]
        end
      end

      ##
      # Instance method for url generation like:
      #
      # ==== Examples
      #
      #   url(:show, :id => 1)
      #   url(:show, :name => 'test', :id => 24)
      #   url(:show, 1)
      #
      def url(*args)
        params = args.extract_options!  # parameters is hash at end
        names, params_array = args.partition{|a| a.is_a?(Symbol)}
        name = names.join("_").to_sym    # route name is concatenated with underscores
        if params.is_a?(Hash)
          params[:format] = params[:format].to_s unless params[:format].nil?
          params = value_to_param(params)
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

      def get(path, *args, &block)
        conditions = @conditions.dup
        route('GET', path, *args, &block)

        @conditions = conditions
        route('HEAD', path, *args, &block)
      end

      private
        # Parse params from the url method
        def value_to_param(value)
          case value
            when Array
              value.map { |v| value_to_param(v) }.compact
            when Hash
              value.inject({}) do |memo, (k,v)|
                v = value_to_param(v)
                memo[k] = v unless v.nil?
                memo
              end
            when nil then nil
            else value.respond_to?(:to_param) ? value.to_param : value
          end
        end

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
        #   get :index, "/"                               # => "/"
        #   get :index, :map => "/"                       # => "/"
        #   get :show, "/show-me"                         # => "/show-me"
        #   get :show,  :map => "/show-me"                # => "/show-me"
        #   get "/foo/bar"                                # => "/show"
        #   get :index, :parent => :user                  # => "/user/:user_id/index"
        #   get :show, :with => :id, :parent => :user     # => "/user/:user_id/show/:id"
        #   get :show, :with => :id                       # => "/show/:id"
        #   get [:show, :id]                              # => "/show/:id"
        #   get :show, :with => [:id, :name]              # => "/show/:id/:name"
        #   get [:show, :id, :name]                       # => "/show/:id/:name"
        #   get :list, :provides => :js                   # => "/list.{:format,js)"
        #   get :list, :provides => :any                  # => "/list(.:format)"
        #   get :list, :provides => [:js, :json]          # => "/list.{!format,js|json}"
        #   get :list, :provides => [:html, :js, :json]   # => "/list(.{!format,js|json})"
        #
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

          # Do padrino parsing. We dup options so we can build HEAD request correctly
          route_options = options.dup
          route_options[:provides] = @_provides if @_provides
          path, *route_options[:with] = path if path.is_a?(Array)
          path, name, options = *parse_route(path, route_options, verb)

          # Sinatra defaults
          define_method "#{verb} #{path}", &block
          unbound_method = instance_method("#{verb} #{path}")

          block =
            if block.arity != 0
              block_arity = block.arity
              proc {
                @block_params = @block_params.slice(0, block_arity) if block_arity > 0
                unbound_method.bind(self).call(*@block_params)
              }
            else
              proc { unbound_method.bind(self).call }
            end

          invoke_hook(:route_added, verb, path, block)

          # HTTPRouter route construction
          route = router.add(path)

          route.name(name) if name
          route.cache = options.key?(:cache) ? options.delete(:cache) : @_cache
          route.send(verb.downcase.to_sym)
          route.host(options.delete(:host)) if options.key?(:host)
          route.user_agent(options.delete(:agent)) if options.key?(:agent)
          if options.key?(:default_values)
            defaults = options.delete(:default_values)
            route.default(defaults) if defaults
          end
          options.delete_if do |option, args|
            if route.send(:significant_variable_names).include?(option)
              route.matching(option => Array(args).first)
              true
            end
          end

          recognition_router.add(path).name(name).to(name)

          # Add Sinatra conditions
          options.each { |option, args|
            if route.respond_to?(option)
              route.send(option, *args)
            else
              send(option, *args)
            end
          }
          conditions, @conditions = @conditions, []
          route.custom_conditions = conditions

          invoke_hook(:padrino_route_added, route, verb, path, args, options, block)

          # Add Application defaults
          if @_controller
            route.before_filters = @filters[:before]
            route.after_filters  = @filters[:after]
            route.use_layout     = @layout
            route.controller     = Array(@_controller).first.to_s
          else
            route.before_filters = @filters[:before] || []
            route.after_filters  = @filters[:after]  || []
          end

          route.to(block)
          route
        end

        def current_controller
          @_controller && @_controller.last
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
            path = map ? map.dup : path.to_s  # The route path
          end

          if path.kind_of?(String) # path i.e "/index" or "/show"
            # Now we need to parse our 'with' params
            if with_params = options.delete(:with)
              path = process_path_for_with_params(path, with_params)
            end

            # Now we need to parse our provides
            options.delete(:provides) if options[:provides].nil?

            if @_use_format or format_params = options[:provides]
              process_path_for_provides(path, format_params)
              options[:matching] ||= {}
              options[:matching][:format] = /[^\.]+/
            end

            # Build our controller
            controller = Array(@_controller).map { |c| c.to_s }

            absolute_map = map && map[0] == ?/

            unless controller.empty?
              # Now we need to add our controller path only if not mapped directly
              if map.blank? and !absolute_map
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
            if !absolute_map and parent_params = options.delete(:parent) || @_parents
              parent_params = Array(@_parents) + Array(parent_params)
              path = process_path_for_parent_params(path, parent_params)
            end

            # Add any controller level map to the front of the path
            path = "#{@_map}/#{path}".squeeze('/') unless absolute_map or @_map.blank?

            # Small reformats
            path.gsub!(%r{/\?$}, '(/)')                    # Remove index path
            path.gsub!(%r{/?index/?}, '/')                 # Remove index path
            path.gsub!(%r{//$}, '/')                       # Remove index path
            path[0,0] = "/" unless path =~ %r{^\(?/}       # Paths must start with a /
            path.sub!(%r{/(\))?$}, '\\1') if path != "/"   # Remove latest trailing delimiter
            path.gsub!(/\/(\(\.|$)/, '\\1')                # Remove trailing slashes
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
          File.join(path, Array(with_params).map { |p| p.inspect }.join("/"))
        end

        ##
        # Processes the existing path and prepends the 'parent' parameters onto the route
        # Used for calculating path in route method
        #
        def process_path_for_parent_params(path, parent_params)
          parent_prefix = parent_params.flatten.compact.uniq.map do |param|
            map  = (param.respond_to?(:map) && param.map ? param.map : param.to_s)
            part = "#{map}/:#{param}_id/"
            part = "(#{part})" if param.respond_to?(:optional) && param.optional?
            part
          end
          [parent_prefix, path].flatten.join("")
        end

        ##
        # Processes the existing path and appends the 'format' suffix onto the route
        # Used for calculating path in route method
        #
        def process_path_for_provides(path, format_params)
          path << "(.:format)" unless path[-10, 10] == '(.:format)'
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
        # ==== Examples
        #   get "/a", :provides => [:html, :js]
        #      # => GET /a      => :html
        #      # => GET /a.js   => :js
        #      # => GET /a.xml  => 404
        #
        #   get "/b", :provides => [:html]
        #      # => GET /b; ACCEPT: html => html
        #      # => GET /b; ACCEPT: js   => 406
        #
        #   enable :treat_format_as_accept
        #   get "/c", :provides => [:html, :js]
        #      # => GET /c.xml => 406
        #
        def provides(*types)
          @_use_format = true
          condition do
            mime_types        = types.map { |t| mime_type(t) }
            request.path_info =~ /\.([^\.\/]+)$/
            url_format        = $1.to_sym if $1
            accepts           = request.accept.map { |a| a.split(";")[0].strip }

            # per rfc2616-sec14:
            # Assume */* if no ACCEPT header is given.
            accepts.delete "*/*"
            if accepts.empty?
              matching_types  = mime_types.slice(0,1)
            else
              matching_types  = (accepts & mime_types)
            end

            if params[:format]
              accept_format = params[:format]
            elsif !url_format && matching_types.first
              type = ::Rack::Mime::MIME_TYPES.find { |k, v| v == matching_types.first }[0].sub(/\./,'').to_sym
              accept_format = CONTENT_TYPE_ALIASES[type] || type
            end

            matched_format = types.include?(:any)            ||
                             types.include?(accept_format)   ||
                             types.include?(url_format)      ||
                             ((!url_format) && request.accept.empty? && types.include?(:html))

            # per rfc2616-sec14:
            # answer with 406 if accept is given but types to not match any
            # provided type
            halt 406 if
              (!url_format && !accepts.empty? && !matched_format) ||
              (settings.respond_to?(:treat_format_as_accept) && settings.treat_format_as_accept && url_format && !matched_format)

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
      #   url(:show, 1)
      #   url("/foo")
      #
      def url(*args)
        # Delegate to Sinatra 1.2 for simple url("/foo")
        # http://www.sinatrarb.com/intro#Generating%20URLs
        return super if args.first.is_a?(String) && !args[1].is_a?(Hash)
        # Delegate to Padrino named route url generation
        self.class.url(*args)
      end
      alias :url_for :url

      def recognize_path(path)
        self.class.recognize_path(path)
      end

      def current_path(*path_params)
        if path_params.last.is_a?(Hash)
          path_params[-1] = params.merge(path_params[-1])
        else
          path_params << params
        end
        @route.url(*path_params)
      end

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
          base.router.runner = self
          if base.router and match = base.router.recognize(@request.env) { |match|
            request.route_obj = match.path.route
            @_response_buffer = nil
            if match.path.route.is_a?(HttpRouter::RegexRoute)
              params_list = match.request.extra_env['router.regex_match'].to_a
              params_list.shift
              @block_params = params_list
              @params.update({:captures => params_list}.merge(@params || {}))
            else
              @block_params = match.param_values
              @params.update(match.params.merge(@params || {}))
            end
            parent_layout = @layout
            @params ||= {}
            @layout = match.path.route.use_layout if match.path.route.use_layout
            # Provide access to the current controller to the request
            # Now we can eval route, but because we have "throw halt" we need to be
            # (en)sure to reset old layout and run controller after filters.
            begin
              old_params = @params
              match.path.route.before_filters.each { |filter| instance_eval(&filter) } if match.path.route.before_filters
              # If present set current controller layout
              @route = match.path.route
              @block_params = @block_params.slice(0, match.path.route.dest.arity) if match.path.route.dest.arity > 0
              match.acceptance_response = catch(:halt) { route_eval(&match.path.route.dest) } || ''
            ensure
              @layout = parent_layout
              (@_pending_after_filters ||= []).concat(match.path.route.after_filters) if match.path.route.after_filters
              @params = old_params
            end
          }
            if match.respond_to?(:path)
              throw :halt, @_response_buffer = match.acceptance_response
            elsif match.respond_to?(:each)
              route_eval do
                match[1].each {|k,v| response[k] = v}
                status match[0]
                route_missing if match[0] == 404
              end
            end
          end

          # Run routes defined in superclass.
          if base.superclass.respond_to?(:router)
            route!(base.superclass, pass_block)
            return
          end

          route_eval(&pass_block) if pass_block

          route_missing
        ensure
          @_pending_after_filters.each { |aft| instance_eval(&aft) } if @_pending_after_filters
        end
    end # InstanceMethods
  end # Routing
end # Padrino