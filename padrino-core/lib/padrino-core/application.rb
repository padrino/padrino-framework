module Padrino
  class ApplicationSetupError < RuntimeError; end
  # Subclasses of this become independent Padrino applications (stemming from Sinatra::Application)
  # These subclassed applications can be easily mounted into other Padrino applications as well.
  class Application < Sinatra::Application

    class << self
      def inherited(subclass)
        CALLERS_TO_IGNORE.concat(PADRINO_IGNORE_CALLERS)
        subclass.default_configuration!
        super # Loading the subclass
        subclass.register Padrino::Routing if defined?(Padrino::Routing)
      end

      # Hooks into when a new instance of the application is created
      # This is used because putting the configuration into inherited doesn't
      # take into account overwritten app settings inside subclassed definitions
      # Only performs the setup first time application is initialized
      def new(*args, &bk)
        setup_application!
        super
      end

      # Makes the routes defined in the block and in the Modules given
      # in `extensions` available to the application
      def controllers(*extensions, &block)
        instance_eval(&block) if block_given?
        include(*extensions)  if extensions.any?
      end

      # With this method we can use layout like rails do or if a block given like sinatra
      # By default we look in your/app/views/layouts/application.(haml|erb|etc)
      # 
      # If you define:
      # 
      #   layout :custom
      # 
      # Padrino look for your/app/views/layouts/custom.(haml|erb|etc)
      def layout(name=:layout, &block)
        return super if block_given?
        @_layout = name
      end

      # Reloads the application files from all defined load paths
      def reload!
        reset_routes! # remove all existing user-defined application routes
        Padrino.load_dependency(self.app_file)  # reload the app file
        load_paths.each { |path| Padrino.load_dependencies(File.join(self.root, path)) } # reload dependencies
      end

      # Resets application routes to only routes not defined by the user
      def reset_routes!
        @routes = Padrino::Application.respond_to?(:dupe_routes) ? Padrino::Application.dupe_routes : {}
      end

      # Setup the application by registering initializers, load paths and logger
      # Invoked automatically when an application is first instantiated
      def setup_application!
        return if @_configured
        self.register_framework_extensions
        self.calculate_paths
        self.register_initializers
        self.require_load_paths
        self.disable :logging # We need do that as default because Sinatra use commonlogger.
        I18n.locale = self.locale
        I18n.load_path += self.translations
        self.get(""){ redirect("#{options.uri_root}/") } if self.uri_root != "/"
        @_configured = true
      end

      protected
        # Defines default settings for Padrino application
        def default_configuration!
          # Overwriting Sinatra defaults
          set :app_file, caller_files.first || $0 # Assume app file is first caller
          set :environment, PADRINO_ENV.to_sym
          set :raise_errors, true if development?
          set :logging, false # !test?
          set :sessions, true
          # Padrino specific
          set :uri_root, "/"
          set :reload, development?
          set :app_name, self.to_s.underscore.to_sym
          set :default_builder, 'StandardFormBuilder'
          set :flash, defined?(Rack::Flash)
          set :authentication, false
          # Padrino locale
          set :locale, :en
          set :translations, Proc.new { Dir[File.join(self.root, "/locale/**/*.{rb,yml}")] }
          set :auto_locale, false
          # Plugin specific
          set :padrino_mailer, defined?(Padrino::Mailer)
          set :padrino_helpers, defined?(Padrino::Helpers)
        end

        # Calculates any required paths after app_file and root have been properly configured
        # Executes as part of the setup_application! method
        def calculate_paths
          raise ApplicationSetupError.new("Please define 'app_file' option for #{self.name} app!") unless self.app_file
          set :views, find_view_path if find_view_path
          set :images_path, File.join(self.public, "/images") unless self.respond_to?(:images_path)
        end

        # Requires the middleware and initializer modules to configure components
        def register_initializers
          use Padrino::RackLogger
          use Padrino::Reloader   if reload?
          use Rack::Flash         if flash?
          register DatabaseSetup  if defined?(DatabaseSetup)
          @initializer_path ||= Padrino.root + '/config/initializers/*.rb'
          Dir[@initializer_path].each { |file| register_initializer(file) }
        end

        # Registers all desired padrino extension helpers/routing
        def register_framework_extensions
          register Padrino::Mailer        if padrino_mailer?
          register Padrino::Helpers       if padrino_helpers?
          register Padrino::AccessControl if authentication?
        end

        # Returns the load_paths for the application (relative to the application root)
        def load_paths
          @load_paths ||= ["urls.rb", "config/urls.rb", "models/*.rb", "mailers/*.rb", "controllers/**/*.rb", "helpers/*.rb"]
        end

        # Requires all files within the application load paths
        def require_load_paths
          load_paths.each { |path| Padrino.require_dependencies(File.join(self.root, path)) }
        end

        # Returns the path to the views directory from root by returning the first that is found
        def find_view_path
          @view_paths = ["views"].collect { |path| File.join(self.root, path) }
          @view_paths.find { |path| Dir[File.join(path, '/**/*')].any? }
        end

        # Registers an initializer with the application
        # register_initializer('/path/to/initializer')
        def register_initializer(file_path)
          Padrino.require_dependencies(file_path)
          file_class = File.basename(file_path, '.rb').camelize
          register "#{file_class}Initializer".constantize
        rescue NameError => e
          logger.error "The module '#{file_class}Initializer' (#{file_path}) didn't loaded properly!"
          logger.error "   Initializer error was '#{e.message}'"
        end
      end

    private
      # Hijacking the sinatra render for do two thing:
      # 
      # * Use layout like rails do
      # * Use render 'path/to/my/template'
      # 
      def render(engine, data=nil, options={}, locals={}, &block)
        @template_cache.clear if Padrino.env != :production && @template_cache && @template_cache.respond_to?(:clear)
        # If an engine is a string probably is a path so we try to resolve them
        if data.nil?
          data   = engine.to_sym
          engine = resolve_template_engine(engine)
        end
        # Use layout as rails do
        if (options[:layout].nil? || options[:layout] == true) && !self.class.templates.has_key?(:layout)
          layout = self.class.instance_variable_defined?(:@_layout) ? self.class.instance_variable_get(:@_layout) : :application
          if layout
            options[:layout] = File.join('layouts', layout.to_s).to_sym
            logger.debug "Rendering layout #{options[:layout]}"
          end
        end
        super
      end

      # Returns the template engine (i.e haml) to use for a given template_path
      # resolve_template_engine('users/new') => :haml
      def resolve_template_engine(template_path)
        resolved_template_path = File.join(self.options.views, template_path.to_s + ".*")
        template_file = Dir[resolved_template_path].first
        raise "Template path '#{template_path}' could not be located in views!" unless template_file
        template_engine = File.extname(template_file)[1..-1].to_sym
      end
      
      # When we set :auto_locale, true then:
      # 
      # * if we pass "/:locale/some/foo" we automatically set teh I18n locale to params[:locale]
      # * if params[:locale] is empty we use the first HTTP_ACCEPT_LANGUAGE
      def route_eval(&block)
        if options.auto_locale
          if params[:locale]
            I18n.locale = params[:locale].to_sym rescue options.locale
          end
        end
        super
      end
  end
end