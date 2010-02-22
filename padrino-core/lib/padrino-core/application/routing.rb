module Padrino
  module Routing
    def self.included(base)
      base.extend Padrino::Routing::ClassMethods
    end

    ##
    # Compatibility with usher
    #
    def route!(base=self.class, pass_block=nil)
      # TODO: remove this when sinatra 1.0 will be released
      if Sinatra::VERSION =~ /^0\.9/
        # enable nested params in Rack < 1.0; allow indifferent access
        can_parse_nested = Rack::Utils.respond_to?(:parse_nested_query)
        @params = can_parse_nested ? indifferent_params(@request.params) : nested_params(@request.params)
        # deliver static files
        static! if options.static? && (request.get? || request.head?)
        # perform before filters
        self.class.filters.each { |block| instance_eval(&block) }
      end # for sinatra = 0.9

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
    def url(name, *params)
      self.class.url(name, *params)
    end
    alias :url_for :url

    ##
    # This is mostly just a helper so request.path_info isn't changed when
    # serving files from the public directory
    #
    def static_file?(path_info)
      return if (public_dir = options.public).nil?
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
    # Method for deliver static files, Sinatra 0.10.x or 1.0.x have this method
    # but for now we use this (because we need a compatibility with 0.9.x) and also
    # because we just have +static_file?+ method.
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
      # And you can call directly these urls:
      #
      #   # => "/admin"
      #   # => "/admin/show/1"
      #
      def controller(*extensions, &block)
        if block_given?
          options = extensions.extract_options!
          @_controller, original_controller = extensions, @_controller
          @_parents, original_parent = options[:parent], @_parents
          instance_eval(&block)
          @_controller, @_parents = original_controller, original_parent
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
      def url(name, *params)
        params.map! do |param|
          if param.is_a?(Hash)
            param[:format] = param[:format].to_s if param.has_key?(:format)
            param.each { |k,v| param[k] = v.to_param if v.respond_to?(:to_param) }
          end
        end
        url = router.generator.generate(name, *params)
        uri_root != "/" ? uri_root + url : url
      end
      alias :url_for :url

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
          # We dup options so we can build HEAD request correctly
          options = options.dup
          # We need check if path is a symbol, if that it's a named route
          map = options.delete(:map)

          if path.kind_of?(Symbol) # path i.e :index or :show
            name = path                       # The route name
            path = map || path.to_s           # The route path
          end

          if path.kind_of?(String) # path i.e "/index" or "/show"
            # Little reformats
            path.sub!(%r{\bindex$}, "")                            # If the route end with /index we remove them
            path = (uri_root == "/" ? "/" : "(/)") if path.blank? # Add a trailing delimiter if empty

            # Now we need to parse our 'with' params
            if with_params = options.delete(:with)
              path = process_path_for_with_params(path, with_params)
            end

            # Now we need to parse our respond_to
            if format_params = options.delete(:respond_to)
              path = process_path_for_respond_to(path, format_params)
            end

            # Build our controller
            controller = Array(@_controller).collect(&:to_s)

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

            # We need to have a path that start with / in some circumstances and that don't end with /
            if path != "(/)" && path != "/"
              path = "/" + path unless path =~ %r{^/}
              path.sub!(/\/$/, '')
            end
          end

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
          path << format_suffix
        end
    end
  end
end