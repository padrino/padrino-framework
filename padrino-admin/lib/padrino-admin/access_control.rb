require_relative 'auth'

module Padrino
  module Admin
    AccessControlError = Padrino::Auth::Error

    ##
    # This module enables access control functionality within a Padrino application.
    #
    module AccessControl
      class << self
        ##
        # Method used by Padrino::Application when we register the extension.
        #
        def registered(app)
          raise Padrino::Auth::Error, 'Register Padrino::Admin::AccessControl instead of Padrino::Auth, not both' if app.extensions.include?(Padrino::Auth)

          app.register Padrino::Admin unless app.extensions.include?(Padrino::Admin)
          app.set :admin_model, 'Account' unless app.respond_to?(:admin_model)
          Padrino::Auth.setup(app, Padrino::Admin::AccessControl::Base.new)
          app.helpers Padrino::Admin::Helpers::AuthenticationHelpers
          app.helpers Padrino::Admin::Helpers::ViewHelpers
        end
        alias included registered

        ##
        # AccessControl sets up Padrino::Auth itself, so registering Auth after it is a no-op.
        #
        def includes_auth?
          true
        end
      end

      ##
      # This base access control class where roles are defined as are authorizations.
      #
      class Base < Padrino::Auth::Rules
        ##
        # Return an array of project_modules.
        #
        def project_modules(account)
          role = account.role.to_sym rescue :any
          authorizations = @authorizations.find_all { |auth| auth.roles.include?(role) }
          authorizations.flat_map(&:project_modules).uniq
        end

        protected

        def authorization_class
          Padrino::Admin::AccessControl::Authorization
        end
      end

      ###
      # Project Authorization Class.
      #
      class Authorization < Padrino::Auth::Authorization
        attr_reader :project_modules

        def initialize(*roles, &block)
          @project_modules = []
          super
        end

        ##
        # Create a project module.
        #
        def project_module(name, path, options = {})
          allow(path)
          @project_modules << ProjectModule.new(name, path, options)
        end
      end

      ##
      # Project Module class.
      #
      class ProjectModule
        attr_reader :name, :options

        def initialize(name, path, options = {})
          @name, @path, @options = name, path, options
        end

        ##
        # Returns the name of the project module humanize them for you.
        #
        def human_name
          Padrino::Inflections.humanize(@name)
        end

        ##
        # Return the path of the project module. If a prefix given will be pre pended.
        #
        # @example
        #   # => /accounts/new
        #   project_module.path
        #   # => /admin/accounts
        #   project_module.path("/admin")
        #
        def path(prefix = nil)
          path = prefix ? File.join(prefix, @path) : @path
          path = File.join(ENV['RACK_BASE_URI'].to_s, path) if ENV['RACK_BASE_URI']
          path
        end
      end
    end
  end
end
