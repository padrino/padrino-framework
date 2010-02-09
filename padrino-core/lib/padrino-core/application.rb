module Padrino
  class ApplicationSetupError < RuntimeError #:nodoc:
  end
  ##
  # Subclasses of this become independent Padrino applications (stemming from Sinatra::Application)
  # These subclassed applications can be easily mounted into other Padrino applications as well.
  # 
  class Application < Sinatra::Application

    class << self
      def inherited(subclass)
        CALLERS_TO_IGNORE.concat(PADRINO_IGNORE_CALLERS)
        subclass.default_configuration!
        Padrino.set_load_paths File.join(subclass.root, "/models")
        Padrino.require_dependencies File.join(subclass.root, "/models.rb")
        Padrino.require_dependencies File.join(subclass.root, "/models/**/*.rb")
        super # Loading the subclass
        subclass.default_filters!
        subclass.default_routes!
        subclass.default_errors!
      end

      ##
      # Hooks into when a new instance of the application is created
      # This is used because putting the configuration into inherited doesn't
      # take into account overwritten app settings inside subclassed definitions
      # Only performs the setup first time application is initialized.
      # 
      def new(*args, &bk)
        setup_application!
        super
      end

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
          @_controller, original = extensions, @_controller
          instance_eval(&block)
          @_controller = original
        else
          include(*extensions)  if extensions.any?
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

      ##
      # With this method we can use layout like rails do or if a block given like sinatra
      # By default we look in your/app/views/layouts/application.(haml|erb|etc)
      # 
      # If you define:
      # 
      #   layout :custom
      # 
      # Padrino look for your/app/views/layouts/custom.(haml|erb|etc)
      # 
      def layout(name=:layout, &block)
        return super if block_given?
        @_layout = name
      end

      ##
      # Reloads the application files from all defined load paths
      # 
      def reload!
        reset_routes! # remove all existing user-defined application routes
        Padrino.load_dependency(self.app_file)  # reload the app file
        load_paths.each { |path| Padrino.load_dependencies(File.join(self.root, path)) } # reload dependencies
      end

      ##
      # Resets application routes to only routes not defined by the user
      # 
      def reset_routes!
        router.reset!
        default_routes!
      end

      ##
      # Setup the application by registering initializers, load paths and logger
      # Invoked automatically when an application is first instantiated
      # 
      def setup_application!
        return if @_configured
        self.register_framework_extensions
        self.calculate_paths
        self.register_initializers
        self.require_load_paths
        self.disable :logging # We need do that as default because Sinatra use commonlogger.
        I18n.locale = self.locale
        I18n.load_path += self.locale_path
        @_configured = true
      end

      protected
        ##
        # Defines default settings for Padrino application
        # 
        def default_configuration!
          # Overwriting Sinatra defaults
          set :app_file, caller_files.first || $0 # Assume app file is first caller
          set :environment, PADRINO_ENV.to_sym
          set :raise_errors, true if development?
          set :logging, false # !test?
          set :sessions, true
          set :public, Proc.new { Padrino.root('public', self.uri_root) }
          # Padrino specific
          set :uri_root, "/"
          set :reload, development?
          set :app_name, self.to_s.underscore.to_sym
          set :default_builder, 'StandardFormBuilder'
          set :flash, defined?(Rack::Flash)
          set :authentication, false
          # Padrino locale
          set :locale, :en
          set :locale_path, Proc.new { Dir[File.join(self.root, "/locale/**/*.{rb,yml}")] }
          set :auto_locale, false
          # Plugin specific
          set :padrino_mailer, defined?(Padrino::Mailer)
          set :padrino_helpers, defined?(Padrino::Helpers)
        end

        ##
        # We need to add almost __sinatra__ images.
        # 
        def default_routes!
          # images resources
          get "/__sinatra__/:image.png" do
            filename = File.dirname(__FILE__) + "/images/#{params[:image]}.png"
            send_file filename
          end
        end

        ##
        # This filter it's used for know the format of the request, and automatically set the content type.
        # 
        def default_filters!
          before do
            request.path_info =~ /\.([^\.\/]+)$/
            @_content_type = ($1 || :html).to_sym
            content_type(@_content_type, :charset => 'utf-8') rescue content_type('application/octet-stream')
          end
        end

        ##
        # This log errors for production environments
        # 
        def default_errors!
          configure :production do
            error ::Exception do
              boom = env['sinatra.error']
              logger.error ["#{boom.class} - #{boom.message}:", *boom.backtrace].join("\n ")
              response.status = 500
              content_type 'text/html'
              '<h1>Internal Server Error</h1>'
            end
          end
        end

        ##
        # Calculates any required paths after app_file and root have been properly configured
        # Executes as part of the setup_application! method
        # 
        def calculate_paths
          raise ApplicationSetupError.new("Please define 'app_file' option for #{self.name} app!") unless self.app_file
          set :views, find_view_path if find_view_path
          set :images_path, File.join(self.public, "/images") unless self.respond_to?(:images_path)
        end

        ##
        # Requires the middleware and initializer modules to configure components
        # 
        def register_initializers
          use Padrino::RackLogger
          use Padrino::Reloader   if reload?
          use Rack::Flash         if flash?
          @initializer_path ||= Padrino.root + '/config/initializers/*.rb'
          Dir[@initializer_path].each { |file| register_initializer(file) }
        end

        ##
        # Registers all desired padrino extension helpers
        # 
        def register_framework_extensions
          register Padrino::Mailer        if padrino_mailer?
          register Padrino::Helpers       if padrino_helpers?
          register Padrino::AccessControl if authentication?
        end

        ##
        # Returns the load_paths for the application (relative to the application root)
        # 
        def load_paths
          @load_paths ||= ["urls.rb", "config/urls.rb", "mailers/*.rb", "controllers/**/*.rb", "controllers.rb", "helpers/*.rb"]
        end

        ##
        # Requires all files within the application load paths
        # 
        def require_load_paths
          load_paths.each { |path| Padrino.require_dependencies(File.join(self.root, path)) }
        end

        ##
        # Returns the path to the views directory from root by returning the first that is found
        # 
        def find_view_path
          @view_paths = ["views"].collect { |path| File.join(self.root, path) }
          @view_paths.find { |path| Dir[File.join(path, '/**/*')].any? }
        end

        ##
        # Registers an initializer with the application
        # register_initializer('/path/to/initializer')
        # 
        def register_initializer(file_path)
          Padrino.require_dependencies(file_path)
          file_class = File.basename(file_path, '.rb').camelize
          register "#{file_class}Initializer".constantize
        rescue NameError => e
          logger.error "The module '#{file_class}Initializer' (#{file_path}) didn't loaded properly!"
          logger.error "   Initializer error was '#{e.message}'"
        end

      private
        ##
        # Rewrite default because now routes can be:
        # 
        #   get :index                                    # => "/"
        #   get :index, :map => "/"                       # => "/"
        #   get :show,  :map => "/show-me"                # => "/show-me"
        #   get "/foo/bar"                                # => "/show"
        #   get :show, :with => :id                       # => "/show/:id"
        #   get :show, :with => [:id, :name]              # => "/show/:id/:name"
        #   get :list, :respond_to => :js                 # => "/list.{:format,js)"
        #   get :list, :respond_to => :any                # => "/list(.:format)"
        #   get :list, :respond_to => [:js, :json]        # => "/list.{!format,js|json}"
        #   gen :list, :respond_to => [:html, :js, :json] # => "/list(.{!format,js|json})"
        # 
        def route(verb, path, options={}, &block)

          # We dup options so we can build HEAD request correctly
          options = options.dup

          # We need check if path is a symbol, if that it's a named route
          map = options.delete(:map)

          if path.kind_of?(Symbol)
            name = path                       # The route name
            path = map || "/#{path}"          # The route path
          end

          if path.kind_of?(String)
            # Little reformats
            path.sub!(/\/index$/, "")                             # If the route end with /index we remove them
            path = (uri_root == "/" ? "/" : "(/)") if path.blank? # Add a trailing delimiter if empty

            # Now we need to parse our with params
            if params = options.delete(:with)
              path += "/" unless path =~ /\/$/
              path += Array(params).collect(&:inspect).join("/")
            end

            # Now we need to parse our respond_to
            if format = options.delete(:respond_to)
              path += case format
                when :any  then "(.:format)"
                when Array then
                  formats   = format.dup # Prevent changes to HEAD verb
                  container = formats.delete(:html) ? "(%s)" : "%s"
                  match     = ".{:format," + formats.collect { |f| "#{f}$" }.join("|") + "}"
                  container % match
                else ".{:format,#{format}}"
              end
            end

            # Build our controller
            controller = Array(@_controller).collect(&:to_s)

            unless controller.empty?
              # Now we need to add our controller path only if not mapped directly
              if map.blank?
                controller_path = controller.join("/")
                path = controller_path + path
              end
              # Here we build the correct name route
              if name
                controller_name = controller.join("_")
                name = "#{controller_name}_#{name}".to_sym unless controller_name.blank?
              end
            end

            # We need to have a path that start with / in some circumstances and that don't end with /
            if path != "(/)" && path != "/"
              path = "/" + path if path !~ /^\//
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
              lambda { unbound_method.bind(self).call(*@block_params) }
            else
              lambda { unbound_method.bind(self).call }
            end

          invoke_hook(:route_added, verb, path, block)

          route = router.add_route(path, options).to(block)
          route.name(name) if name
          route
        end
    end # self

    ##
    # Return the request format, this is useful when we need to respond to a given content_type like:
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
    # Instance method for url generation like:
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

    private

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

      ##
      # Compatibility with usher
      # 
      def route!(base=self.class, pass_block=nil)
        # TODO: remove this when sinatra 1.0 will be released
        if Sinatra::VERSION =~ /^0\.9/
          # enable nested params in Rack < 1.0; allow indifferent access
          @params = if Rack::Utils.respond_to?(:parse_nested_query)
            indifferent_params(@request.params)
          else
            nested_params(@request.params)
          end
          # deliver static files
          static! if options.static? && (request.get? || request.head?)
          # perform before filters
          self.class.filters.each { |block| instance_eval(&block) }
        end

        # Usher
        if self.class.router and match = self.class.router.recognize(@request, @request.path_info)
          @block_params = match.params.map{|p| p.last}
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
      # When we set :auto_locale, true then if we use param locale like:
      # 
      #   get "/:locale/some/foo" do; ...; end
      # 
      # we automatically set the I18n locale to params[:locale]
      # 
      def route_eval(&block)
        if options.auto_locale
          if params[:locale]
            I18n.locale = params[:locale].to_sym rescue options.locale
          end
        end
        super
      end

      ##
      # Hijacking the sinatra render for do three thing:
      # 
      # * Use layout like rails do
      # * Use render 'path/to/my/template' (without symbols)
      # * Use render 'path/to/my/template' (with auto enegine lookup)
      # 
      def render(engine, data=nil, options={}, locals={}, &block)
        # TODO: remove these @template_cache.respond_to?(:clear) when sinatra 1.0 will be released
        @template_cache.clear if Padrino.env != :production && @template_cache && @template_cache.respond_to?(:clear)
        # If engine is an hash we convert to json
        return engine.to_json if engine.is_a?(Hash)
        # If an engine is a string probably is a path so we try to resolve them
        if data.nil?
          data   = engine.to_sym
          engine = resolve_template_engine(engine)
        end
        # Use layout as rails do
        if (options[:layout].nil? || options[:layout] == true) && !self.class.templates.has_key?(:layout)
          layout = self.class.instance_variable_defined?(:@_layout) ? self.class.instance_variable_get(:@_layout) : :application
          if layout
            # We look first for views/layout_name.ext then then for views/layouts/layout_name.ext
            options[:layout] = Dir["#{self.options.views}/#{layout}.*"].present? ? layout.to_sym : File.join('layouts', layout.to_s).to_sym
            logger.debug "Rendering layout #{options[:layout]}"
          end
        end
        super
      end

      ##
      # Returns the template engine (i.e haml) to use for a given template_path
      # resolve_template_engine('users/new') => :haml
      # 
      def resolve_template_engine(template_path)
        resolved_template_path = File.join(self.options.views, template_path.to_s + ".*")
        template_file = Dir[resolved_template_path].first
        raise "Template path '#{template_path}' could not be located in views!" unless template_file
        template_engine = File.extname(template_file)[1..-1].to_sym
      end
  end # Application
end # Padrino