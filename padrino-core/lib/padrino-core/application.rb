module Padrino
  class ApplicationSetupError < RuntimeError; end
  # Subclasses of this become independent Padrino applications (stemming from Sinatra::Application)
  # These subclassed applications can be easily mounted into other Padrino applications as well.
  class Application < Sinatra::Application

    def logger
      @log_stream ||= self.class.log_to_file? ? Padrino.root("log/#{PADRINO_ENV.downcase}.log") : $stdout
      @logger   ||= Logger.new(@log_stream)
    end

    class << self
      def inherited(subclass)
        subclass.default_configuration!
        super # Loading the subclass
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
        @routes = Padrino::Application.dupe_routes if reload? # This performs a basic controller reload
        instance_eval(&block) if block_given?
        include(*extensions)  if extensions.any?
      end

      # Makes the urls defined in the block and in the Modules given
      # in `extensions` available to the application
      def urls(*extensions, &block)
        instance_eval(&block) if block_given?
        include(*extensions)  if extensions.any?
      end

      protected

      # Setup the application by registering initializers, load paths and logger
      # Invoked automatically when an application is first instantiated
      def setup_application!
        return if @configured
        self.calculate_paths
        self.register_initializers
        self.register_framework_extensions
        self.require_load_paths
        self.setup_logger
        @configured = true
      end

      # Defines default settings for Padrino application
      def default_configuration!
        # Overwriting Sinatra defaults
        set :raise_errors, true if development?
        set :logging, true
        set :sessions, true
        set :log_to_file, !development?
        set :reload, development?
        # Padrino specific
        set :app_name, self.to_s.underscore.to_sym
        set :environment, PADRINO_ENV.to_sym
        set :default_builder, 'StandardFormBuilder'
        enable :flash
        # Plugin specific
        enable :padrino_helpers
      end

      # Calculates any required paths after app_file and root have been properly configured
      # Executes as part of the setup_application! method
      def calculate_paths
        raise ApplicationSetupError.new("Please specify 'app_file' configuration option!") unless self.app_file
        set :views, find_view_path if find_view_path
        set :images_path, File.join(self.public, "/images") unless self.respond_to?(:images_path)
      end

      # Requires the middleware and initializer modules to configure components
      def register_initializers
        use Rack::Session::Cookie
        use Rack::Flash if flash?
        use Padrino::Reloader if reload?
        register DatabaseSetup if defined?(DatabaseSetup)
        Dir[Padrino.root + '/config/initializers/*.rb'].each do |file|
          Padrino.load_dependencies(file)
          file_class = File.basename(file, '.rb').classify
          register "#{file_class}Initializer".constantize
        end
      end

      # Registers all desired padrino extension helpers/routing
      def register_framework_extensions
        register Padrino::Routing
        register Padrino::Mailer
        register Padrino::Helpers  if padrino_helpers?
      end

      # Require all files within the application's load paths
      def require_load_paths
        load_paths.each { |path| Padrino.load_dependencies(File.join(self.root, path)) }
      end

      # Creates the log directory and redirects output to file if needed
      def setup_logger
        return unless self.log_to_file?
        FileUtils.mkdir_p 'log' unless File.exists?('log')
        log = File.new("log/#{PADRINO_ENV.downcase}.log", "a+")
        $stdout.reopen(log)
        $stderr.reopen(log)
      end

      # Returns the load_paths for the application (relative to the application root)
      def load_paths
        @load_paths ||= ["urls.rb", "config/urls.rb", "models/*.rb", "app/models/*.rb",
                         "controllers/*.rb", "app/controllers/*.rb","helpers/*.rb", "app/helpers/*.rb"]
      end

      # Returns the path to the views directory from root by returning the first that is found
      def find_view_path
        @view_paths = ["views", "app/views"].collect { |path| File.join(self.root, path) }
        @view_paths.find { |path| Dir[File.join(path, '/**/*')].any? }
      end
    end
  end
end
