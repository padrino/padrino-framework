require 'usher' unless defined?(Usher)
require 'padrino-core/support_lite' unless String.method_defined?(:blank!)

module Padrino
  ##
  # Padrino provides advanced routing definition support to make routes and url generation much easier.
  # This routing system supports named route aliases and easy access to url paths.
  # The benefits of this is that instead of having to hard-code route urls into every area of your application,
  # now we can just define the urls in a single spot and then attach an alias which can be used to refer
  # to the url throughout the application.
  #
  module Routing
    class UnrecognizedException < RuntimeError #:nodoc:
    end

    def self.registered(app)
      app.send(:include, Padrino::Routing)
    end

    def self.included(base)
      base.extend Padrino::Routing::ClassMethods
    end

    ##
    # Compatibility with usher
    #
    def route!(base=self.class, pass_block=nil)
      # Usher
      if self.class.router and match = self.class.router.recognize(@request, @request.path_info)
        @block_params = match.params.map { |p| p.last }
        @params = @params ? @params.merge(match.params_as_hash) : match.params_as_hash
        pass_block = catch(:pass) do
          route_eval(&match.destination)
        end
      elsif base.superclass.respond_to?(:routes)
        route! base.superclass
      else
        route_missing
      end
    end

    ##
    # Instance method for url generation like:
    #
    # ==== Examples
    #
    #   url(:show, :id => 1)
    #   url(:show, :name => :test)
    #   url("/show/:id/:name", :id => 1, :name => foo)
    #
    def url(*names)
      self.class.url(*names)
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
    # Return the request format, this is useful when we need to respond to a given content_type like:
    #
    # ==== Examples
    #
    #   get :index, :respond_to => :any do
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

    ##
    # Method for deliver static files.
    #
    def static!
      if path = static_file?(request.path_info)
        send_file(path, :disposition => nil)
      end
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
      # You can supply default values:
      #
      #   controller :lang => :de do
      #     get :index, :map => "/:lang" do; ...; end
      #   end
      #
      # And you can call directly these urls:
      #
      #   # => "/admin"
      #   # => "/admin/show/1"
      #
      def controller(*extensions, &block)
        if block_given?
          options = extensions.extract_options!
          @_controller, original_controller = extensions, @_controller
          @_parents,    original_parent     = options.delete(:parent), @_parents
          @_defaults,   original_defaults   = options, @_defaults
          instance_eval(&block)
          @_controller, @_parents, @_defaults = original_controller, original_parent, original_defaults
        else
          include(*extensions) if extensions.any?
        end
      end
      alias :controllers :controller

      ##
      # Usher router, for fatures and configurations see: http://github.com/joshbuddy/usher
      #
      # ==== Examples
      #
      #   router.add_route('/greedy/{!:greed,.*}')
      #   router.recognize_path('/simple')
      #
      def router
        @router ||= Usher.new(:request_methods => [:request_method, :host, :port, :scheme],
                              :ignore_trailing_delimiters => true,
                              :generator => Usher::Util::Generators::URL.new)
        block_given? ? yield(@router) : @router
      end
      alias :urls :router

      ##
      # Instance method for url generation like:
      #
      # ==== Examples
      #
      #   url(:show, :id => 1)
      #   url(:show, :name => :test)
      #   url("/show/:id/:name", :id => 1, :name => foo)
      #
      def url(*names)
        params =  names.extract_options! # parameters is hash at end
        name = names.join("_").to_sym    # route name is concatenated with underscores
        if params.is_a?(Hash)
          params[:format] = params[:format].to_s if params.has_key?(:format)
          params.each { |k,v| params[k] = v.to_param if v.respond_to?(:to_param) }
        end
        url = router.generator.generate(name, params)
        url = uri_root + url if defined?(uri_root) && uri_root != "/"
        url
      rescue Usher::UnrecognizedException
        route_error = "route mapping for url(#{name.inspect}) could not be found!"
        raise Padrino::Routing::UnrecognizedException.new(route_error)
      end
      alias :url_for :url

      ##
      # Returns the cached route for the given path and options.
      #
      def fetch_route(path, options)
        key = [path, options, @_controller, @_parents]
        (@_cached_route ||= {})[key]
      end

      ###
      # Caches the given route
      #
      def cache_route!(original, parsed)
        key = original.push(@_controller, @_parents)
        (@_cached_route ||= {})[key] = parsed if parsed
      end

      private
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
        #   get :list, :respond_to => :js                 # => "/list.{:format,js)"
        #   get :list, :respond_to => :any                # => "/list(.:format)"
        #   get :list, :respond_to => [:js, :json]        # => "/list.{!format,js|json}"
        #   get :list, :respond_to => [:html, :js, :json] # => "/list(.{!format,js|json})"
        #
        def route(verb, path, options={}, &block)
          # Do padrino parsing. We dup options so we can build HEAD request correctly
          path, name, options = *parse_route(path, options.dup)

          # Standard Sinatra requirements
          options[:conditions] ||= {}
          options[:conditions][:request_method] = verb
          options[:conditions][:host] = options.delete(:host) if options.key?(:host)

          # Because of self.options.host
          host_name(options.delete(:host)) if options.key?(:host)

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
          route = router.add_route(path, options).to(block)
          route.name(name) if name
          route
        end

        ##
        # Returns the final parsed route details (modified to reflect all Padrino options)
        # given the raw route. Raw route passed in could be a named alias or a string and
        # is parsed to reflect respond_to formats, controllers, parents, 'with' parameters,
        # and other options.
        #
        def parse_route(path, options)
          # We check and return the cached route if present
          cached_route = fetch_route(path, options)
          return cached_route if cached_route

          # We need save our originals path/options so we can perform correctly cache.
          original = [path, options.dup]

          # We need check if path is a symbol, if that it's a named route
          map = options.delete(:map)

          if path.kind_of?(Symbol) # path i.e :index or :show
            name = path                       # The route name
            path = map || path.to_s           # The route path
          end

          if path.kind_of?(String) # path i.e "/index" or "/show"
            # Now we need to parse our 'with' params
            if with_params = options.delete(:with)
              path = process_path_for_with_params(path, with_params)
            end

            # Now we need to parse our respond_to
            if format_params = options.delete(:respond_to)
              path = process_path_for_respond_to(path, format_params)
            end

            # Build our controller
            controller = Array(@_controller).collect { |c| c.to_s }

            unless controller.empty?
              # Now we need to add our controller path only if not mapped directly
              if map.blank?
                controller_path = controller.join("/")
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
            path.sub!(%r^/index(\(.\{:format[\,\w\$\|]*\}\))$^, '\1') # Remove index from formatted routes
            path.sub!(%r{\bindex(.*)$}, '\1')                         # If the route contains /index we remove that
            path = (uri_root == "/" ? "/" : "(/)") if path.blank?     # Add a trailing delimiter if path is empty

            # We need to have a path that start with / in some circumstances and that don't end with /
            if path != "(/)" && path != "/"
              path = "/" + path unless path =~ %r{^/}
              path.sub!(%r{/$}, '')
            end

            # We need to fix a few differences between the usher and sintra router
            path.sub!(%r{/\?$}, '(/)') #  '/foo/?' => '/foo(/)'
          end

          # Merge in option defaults
          options.reverse_merge!(:default_values => @_defaults)

          # Save parsed
          parsed = [path, name, options.dup]

          # Perform caching
          cache_route!(original, parsed) unless reload?
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
        def process_path_for_respond_to(path, format_params)
          format_suffix = case format_params
            when :any  then "(.:format)"
            when Array then
              formats   = format_params.dup # Prevent changes to HEAD verb
              container = formats.delete(:html) ? "(%s)" : "%s"
              match     = ".{:format," + formats.collect { |f| "#{f}$" }.join("|") + "}"
              container % match
            else ".{:format,#{format_params}}"
          end
          path + format_suffix
        end
    end # ClassMethods
  end # Routing
end # Padrino