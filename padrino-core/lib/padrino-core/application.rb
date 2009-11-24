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

      # Reloads the application files from all defined load paths
      def reload!
        reset_routes! # remove all existing user-defined application routes
        Padrino.load_dependency(self.app_file)  # reload the app file
        load_paths.each { |path| Padrino.load_dependencies(File.join(self.root, path)) }
      end

      # Resets application routes to only routes not defined by the user
      def reset_routes!
        @routes = Padrino::Application.dupe_routes
      end

      # Setup the application by registering initializers, load paths and logger
      # Invoked automatically when an application is first instantiated
      def setup_application!
        return if @_configured
        self.register_framework_extensions
        self.calculate_paths
        self.register_initializers
        self.require_load_paths
        @_configured = true
      end

      protected

      # Defines default settings for Padrino application
      def default_configuration!
        # Overwriting Sinatra defaults
        set :app_file, caller_files.first || $0 # Assume app file is first caller
        set :environment, PADRINO_ENV.to_sym
        set :raise_errors, true if development?
        set :logging, !test?
        set :sessions, true
        # Padrino specific
        set :reload, development?
        set :app_name, self.to_s.underscore.to_sym
        set :default_builder, 'StandardFormBuilder'
        set :flash, defined?(Rack::Flash)
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
        use Rack::Session::Cookie
        use Rack::Flash if flash?
        use Padrino::Reloader if reload?
        use Rack::CommonLogger, logger if logging?
        register DatabaseSetup if defined?(DatabaseSetup)
        @initializer_path ||= Padrino.root + '/config/initializers/*.rb'
        Dir[@initializer_path].each { |file| register_initializer(file) }
      end

      # Registers all desired padrino extension helpers/routing
      def register_framework_extensions
        register Padrino::Mailer   if padrino_mailer?
        register Padrino::Helpers  if padrino_helpers?
      end

      # Requires all files within the application load paths
      def require_load_paths
        load_paths.each { |path| Padrino.require_dependencies(File.join(self.root, path)) }
      end

      # Returns the load_paths for the application (relative to the application root)
      def load_paths
        @load_paths ||= ["urls.rb", "config/urls.rb", "models/*.rb", "app/models/*.rb",
                         "mailers/*.rb", "app/mailers/*.rb", "controllers/*.rb", "app/controllers/*.rb",
                         "helpers/*.rb", "app/helpers/*.rb"]
      end

      # Returns the path to the views directory from root by returning the first that is found
      def find_view_path
        @view_paths = ["views", "app/views"].collect { |path| File.join(self.root, path) }
        @view_paths.find { |path| Dir[File.join(path, '/**/*')].any? }
      end

      # Registers an initializer with the application
      # register_initializer('/path/to/initializer')
      def register_initializer(file_path)
        Padrino.require_dependencies(file_path)
        file_class = File.basename(file_path, '.rb').camelize
        register "#{file_class}Initializer".constantize
      rescue NameError => e
        logger.error "The module '#{file_class}Initializer' (#{file_path}) didn't loaded properly!" if logging?
        logger.error "   Initializer error was '#{e.message}'" if logging?
      end
    end
  end
end
