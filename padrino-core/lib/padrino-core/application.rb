require 'padrino-core/application/flash'
require 'padrino-core/application/routing'
require 'padrino-core/application/show_exceptions'
require 'padrino-core/application/authenticity_token'
require 'padrino-core/application/application_setup'
require 'padrino-core/application/params_protection'

module Padrino
  ##
  # Subclasses of this become independent Padrino applications
  # (stemming from Sinatra::Application).
  # These subclassed applications can be easily mounted into other
  # Padrino applications as well.
  #
  class Application < Sinatra::Base
    register Padrino::ApplicationSetup
    register Padrino::Routing
    register Padrino::ParamsProtection

    ##
    # Returns the logger for this application.
    #
    # @return [Padrino::Logger] Logger associated with this app.
    #
    def logger
      Padrino.logger
    end

    class << self
      def inherited(base)
        begun_at = Time.now
        super(base)
        base.prerequisites.replace(self.prerequisites.dup)
        base.default_configuration!
        logger.devel :setup, begun_at, base
      end

      def callers_to_ignore
        @callers_to_ignore ||= super + PADRINO_IGNORE_CALLERS
      end

      ##
      # Reloads the application files from all defined load paths.
      #
      # This method is used from our Padrino Reloader during development mode
      # in order to reload the source files.
      #
      # @return [TrueClass]
      #
      # @example
      #   MyApp.reload!
      #
      def reload!
        logger.devel "Reloading application #{settings}"
        reset!
        reset_router!
        Padrino.require_dependencies(settings.app_file, :force => true)
        require_dependencies
        default_routes
        default_errors
        I18n.reload! if defined?(I18n)
        true
      end

      ##
      # Resets application routes to only routes not defined by the user.
      #
      # @return [TrueClass]
      #
      # @example
      #   MyApp.reset_routes!
      #
      def reset_routes!
        reset_router!
        default_routes
        true
      end

      ##
      # Returns the routes of our app.
      #
      # @example
      #   MyApp.routes
      #
      def routes
        router.routes
      end

      ##
      # Returns an absolute path of view in application views folder.
      #
      # @example
      #   Admin.view_path 'users/index' #=> "/home/user/test/admin/views/users/index"
      #
      def view_path(view)
        File.expand_path(view, views)
      end

      ##
      # Returns an absolute path of application layout.
      #
      # @example
      #   Admin.layout_path :application #=> "/home/user/test/admin/views/layouts/application"
      #
      def layout_path(layout)
        view_path("layouts/#{layout}")
      end

      ##
      # Run the Padrino app as a self-hosted server using
      # Thin, Mongrel or WEBrick (in that order).
      #
      # @see Padrino::Server#start
      #
      def run!(options={})
        return unless Padrino.load!
        Padrino.mount(settings.to_s).to('/')
        Padrino.run!(options)
      end

      ##
      # Returns default list of path globs to load as dependencies.
      # Appends custom dependency patterns to the be loaded for your Application.
      #
      # @return [Array]
      #   list of path globs to load as dependencies
      #
      # @example
      #   MyApp.dependencies << "#{Padrino.root}/uploaders/**/*.rb"
      #   MyApp.dependencies << Padrino.root('other_app', 'controllers.rb')
      #
      def dependencies
        [
          'urls.rb',
          'config/urls.rb',
          'mailers/*.rb',
          'mailers.rb',
          'controllers/**/*.rb',
          'controllers.rb',
          'helpers/**/*.rb',
          'helpers.rb',
        ].flat_map{ |file| Dir.glob(File.join(settings.root, file)) }
      end

      ##
      # An array of file to load before your app.rb, basically are files
      # which our app depends on.
      #
      # By default we look for files:
      #
      #   # List of default files that we are looking for:
      #   yourapp/models.rb
      #   yourapp/models/**/*.rb
      #   yourapp/lib.rb
      #   yourapp/lib/**/*.rb
      #
      # @example Adding a custom prerequisite
      #   MyApp.prerequisites << Padrino.root('my_app', 'custom_model.rb')
      #
      def prerequisites
        @_prerequisites ||= []
      end

      def default(option, *args, &block)
        set(option, *args, &block) unless respond_to?(option)
      end

      protected

      ##
      # Requires all files within the application load paths.
      #
      def require_dependencies
        Padrino.require_dependencies(dependencies, :force => true)
      end
    end
  end
end
