module Padrino
  class ApplicationSetupError < RuntimeError #:nodoc:
  end

  ##
  # Subclasses of this become independent Padrino applications (stemming from Sinatra::Application)
  # These subclassed applications can be easily mounted into other Padrino applications as well.
  #
  class Application < Sinatra::Base
    register Padrino::Routing   # Support for advanced routing, controllers, url_for
    register Padrino::Rendering # Support for enhanced rendering with template detection

    class << self

      def inherited(subclass) #:nodoc:
        CALLERS_TO_IGNORE.concat(PADRINO_IGNORE_CALLERS)
        subclass.default_configuration!
        Padrino.set_load_paths File.join(subclass.root, "/models")
        Padrino.require_dependencies File.join(subclass.root, "/models.rb")
        Padrino.require_dependencies File.join(subclass.root, "/models/**/*.rb")
        super(subclass) # Loading the subclass inherited method
      end

      ##
      # Hooks into when a new instance of the application is created
      # This is used because putting the configuration into inherited doesn't
      # take into account overwritten app settings inside subclassed definitions
      # Only performs the setup first time application is initialized.
      #
      def new(*args, &bk)
        setup_application!
        logging, logging_was = false, logging
        show_exceptions, show_exceptions_was = false, show_exceptions
        super(*args, &bk)
      ensure
        logging, show_exceptions = logging_was, show_exceptions_was
      end

      ##
      # Reloads the application files from all defined load paths
      #
      # This method is used from our Padrino Reloader during development mode
      # in order to reload the source files.
      #
      # ==== Examples
      #
      #   MyApp.reload!
      #
      def reload!
        reset! # Reset sinatra app
        reset_routes! # Remove all existing user-defined application routes
        Padrino.require_dependencies(File.join(self.root, "/models.rb")) # Reload models class
        Padrino.require_dependencies(File.join(self.root, "/models/**/*.rb")) # Reload all models
        Padrino.require_dependencies(self.app_file) # Reload the app file
        register_initializers # Reload our middlewares
        require_load_paths # Reload dependencies
        default_filters! # Reload filters
        default_errors!  # Reload our errors
        I18n.reload! if defined?(I18n) # Reload also our translations
      end

      ##
      # Resets application routes to only routes not defined by the user
      #
      # ==== Examples
      #
      #   MyApp.reset_routes!
      #
      def reset_routes!
        reset_router!
        default_routes!
      end

      ##
      # Returns the routes of our app.
      #
      # ==== Examples
      #
      #   MyApp.routes
      #
      def routes
        router.routes
      end

      ##
      # Setup the application by registering initializers, load paths and logger
      # Invoked automatically when an application is first instantiated
      #
      def setup_application!
        return if @_configured
        self.register_initializers
        self.require_load_paths
        self.disable :logging # We need do that as default because Sinatra use commonlogger.
        self.default_filters!
        self.default_routes!
        self.default_errors!
        if defined?(I18n)
          I18n.load_path << self.locale_path
          I18n.reload!
        end
        @_configured = true
      end

      ##
      # Run the Padrino app as a self-hosted server using
      # Thin, Mongrel or WEBrick (in that order)
      #
      def run!(options={})
        return unless Padrino.load!
        set options
        handler      = detect_rack_handler
        handler_name = handler.name.gsub(/.*::/, '')
        puts "=> #{self.name}/#{Padrino.version} has taken the stage #{Padrino.env} on #{port}" unless handler_name =~/cgi/i
        handler.run self, :Host => bind, :Port => port do |server|
          trap(:INT) do
            ## Use thins' hard #stop! if available, otherwise just #stop
            server.respond_to?(:stop!) ? server.stop! : server.stop
            puts "<= #{self.name} has ended his set (crowd applauds)" unless handler_name =~/cgi/i
          end
          set :running, true
        end
      rescue Errno::EADDRINUSE => e
        puts "<= Someone is already performing on port #{port}!"
      end

      protected
        ##
        # Defines default settings for Padrino application
        #
        def default_configuration!
          # Overwriting Sinatra defaults
          set :app_file, File.expand_path(caller_files.first || $0) # Assume app file is first caller
          set :environment, Padrino.env
          set :reload, Proc.new { development? }
          set :logging, Proc.new { development? }
          set :method_override, true
          set :sessions, false
          set :public, Proc.new { Padrino.root('public', uri_root) }
          set :views, Proc.new { File.join(root,   "views") }
          set :images_path, Proc.new { File.join(public, "images") }
          # Padrino specific
          set :uri_root, "/"
          set :app_name, self.to_s.underscore.to_sym
          set :default_builder, 'StandardFormBuilder'
          set :flash, defined?(Rack::Flash)
          set :authentication, false
          # Padrino locale
          set :locale_path, Proc.new { Dir[File.join(self.root, "/locale/**/*.{rb,yml}")] }
          # Load the Global Configurations
          class_eval(&Padrino.configure_apps) if Padrino.configure_apps
        end

        ##
        # We need to add almost __sinatra__ images.
        #
        def default_routes!
          configure :development do
            get '/__sinatra__/:image.png' do
              content_type :png
              filename = File.dirname(__FILE__) + "/images/#{params[:image]}.png"
              send_file filename
            end
          end
        end

        ##
        # This filter it's used for know the format of the request, and automatically set the content type.
        #
        def default_filters!
          before do
            @_content_type = :html
            response['Content-Type'] = 'text/html;charset=utf-8'
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
        # Requires the Padrino middleware
        #
        def register_initializers
          use Padrino::ShowExceptions         if show_exceptions?
          use Padrino::Logger::Rack, uri_root if Padrino.logger && logging?
          use Padrino::Reloader::Rack         if reload?
          use Rack::Flash                     if flash?
        end

        ##
        # Returns the load_paths for the application (relative to the application root)
        #
        def load_paths
          @load_paths ||= ["urls.rb", "config/urls.rb", "mailers/*.rb", "mailers.rb",
                           "controllers/**/*.rb", "controllers.rb", "helpers/**/*.rb", "helpers.rb"]
        end

        ##
        # Requires all files within the application load paths
        #
        def require_load_paths
          load_paths.each { |path| Padrino.require_dependencies(File.join(self.root, path)) }
        end
    end # self
  end # Application
end # Padrino
