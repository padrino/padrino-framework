module Padrino
  ##
  # Holds setup-oriented methods for Padrino::Application.
  #
  module ApplicationSetup
    def self.registered(app)
      app.extend(ClassMethods)
    end

    module ClassMethods
      ##
      # Defines default settings for Padrino application.
      #
      def default_configuration!
        set :app_file, File.expand_path(caller_files.first || $0)
        set :app_name, Inflections.underscore(settings).to_sym

        set :environment, Padrino.env
        set :reload, proc { development? }
        set :logging, proc { development? }

        set :method_override, true
        set :default_builder, 'StandardFormBuilder'

        default_paths
        default_security
        global_configuration
        setup_prerequisites
      end

      ##
      # Setup the application by registering initializers, load paths and logger.
      # Invoked automatically when an application is first instantiated.
      #
      # @return [TrueClass]
      #
      def setup_application!
        return if @_configured
        require_dependencies
        default_routes
        default_errors
        setup_locale
        precompile_routes!
        @_configured = true
      end

      def precompile_routes?
        settings.respond_to?(:precompile_routes) && settings.precompile_routes?
      end

      def precompile_routes!
        compiled_router.prepare!
        compiled_router.engine.compile!
      end

      private

      def default_paths
        set :locale_path,   proc { Dir.glob File.join(root, 'locale/**/*.{rb,yml}') }
        set :views,         proc { File.join(root, 'views') }

        set :uri_root,      '/'
        set :public_folder, proc { Padrino.root('public', uri_root) }
        set :images_path,   proc { File.join(public_folder, 'images') }
        set :base_url,      'http://localhost'
      end

      def default_security
        set :protection, :except => :path_traversal
        set :sessions, false
        set :protect_from_csrf, false
        set :report_csrf_failure, false
        set :allow_disabled_csrf, false
      end

      ##
      # Applies global padrino configuration blocks to current application.
      #
      def global_configuration
        Padrino.global_configurations.each do |configuration|
          class_eval(&configuration)
        end
      end

      def setup_prerequisites
        prerequisites.concat(default_prerequisites).uniq!
        Padrino.require_dependencies(prerequisites)
      end

      ##
      # Returns globs of default paths of application prerequisites.
      #
      def default_prerequisites
        [
          '/models.rb',
          '/models/**/*.rb',
          '/lib.rb',
          '/lib/**/*.rb',
        ].map{ |glob| File.join(settings.root, glob) }
      end

      # Overrides the default middleware for Sinatra based on Padrino conventions.
      # Also initializes the application after setting up the middleware.
      def setup_default_middleware(builder)
        setup_sessions builder
        builder.use Sinatra::ExtendedRack           if defined?(EventMachine)
        builder.use Padrino::ShowExceptions         if show_exceptions?
        builder.use Padrino::Logger::Rack, uri_root if Padrino.logger && logging?
        builder.use Padrino::Reloader::Rack         if reload?
        builder.use Rack::MethodOverride            if method_override?
        builder.use Rack::Head
        register Padrino::Flash
        setup_protection builder
        setup_csrf_protection builder
        setup_application!
      end

      ##
      # We need to add almost __sinatra__ images.
      #
      def default_routes
        configure :development do
          get '*__sinatra__/:image.png' do
            content_type :png
            send_file(File.dirname(__FILE__) + "/../images/#{params[:image]}.png")
          end
        end
      end

      ##
      # This log errors for production environments.
      #
      def default_errors
        configure :production do
          error ::Exception do
            logger.exception env['sinatra.error']
            halt(500, { 'Content-Type' => 'text/html' }, ['<h1>Internal Server Error</h1>'])
          end unless errors.has_key?(::Exception)
        end
      end

      def setup_locale
        return unless defined? I18n
        Reloader.special_files += locale_path
        I18n.load_path << locale_path
        I18n.reload!
      end

      # allow custome session management
      def setup_sessions(builder)
        if sessions.kind_of?(Hash) && sessions[:use]
          builder.use sessions[:use], sessions[:config] || {}
        else
          super
        end
      end

      # sets up csrf protection for the app
      def setup_csrf_protection(builder)
        check_csrf_protection_dependency

        if protect_from_csrf?
          options = options_for_csrf_protection_setup
          options.merge!(protect_from_csrf) if protect_from_csrf.kind_of?(Hash)
          builder.use(options[:except] ? Padrino::AuthenticityToken : Rack::Protection::AuthenticityToken, options)
        end
      end

      # returns the options used in the builder for csrf protection setup
      def options_for_csrf_protection_setup
        options = { :logger => logger }
        if report_csrf_failure? || allow_disabled_csrf?
          options.merge!(
            :reaction   => :report,
            :report_key => 'protection.csrf.failed'
          )
        end
        options
      end

      # warn if the protect_from_csrf is active but sessions are not
      def check_csrf_protection_dependency
        if (protect_from_csrf? && !sessions?) && !defined?(Padrino::IGNORE_CSRF_SETUP_WARNING)
          warn(<<-ERROR)
  `protect_from_csrf` is activated, but `sessions` seem to be off. To enable csrf
  protection, use:

      enable :sessions

  or deactivate protect_from_csrf:

      disable :protect_from_csrf

  If you use a different session store, ignore this warning using:

      # in boot.rb:
      Padrino::IGNORE_CSRF_SETUP_WARNING = true
          ERROR
        end
      end
    end
  end
end
