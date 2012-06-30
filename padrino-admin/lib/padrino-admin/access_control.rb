require 'active_support/core_ext/class/attribute_accessors'

module Padrino
  module Admin
    class AccessControlError < StandardError # @private
    end
    ##
    # This module enables access control functionality within a padrino application.
    #
    module AccessControl
      class << self
        ##
        # Method used by Padrino::Application when we register the extension
        #
        def registered(app)
          app.set :session_id, "_padrino_#{File.basename(Padrino.root)}_#{app.app_name}".to_sym
          app.set :admin_model, 'Account' unless app.respond_to?(:admin_model)
          app.helpers Padrino::Admin::Helpers::AuthenticationHelpers
          app.helpers Padrino::Admin::Helpers::ViewHelpers
          app.before { login_required }
          app.send(:cattr_accessor, :access_control)
          app.send(:access_control=, Padrino::Admin::AccessControl::Base.new)
        end
        alias :included :registered
      end

      ##
      # This base access control class where roles are defined as are authorizations.
      #
      class Base
        def initialize # @private
          @roles, @authorizations, @project_modules = [], [], []
        end

        ##
        # We map project modules for a given role or roles
        #
        def roles_for(*roles, &block)
          raise Padrino::Admin::AccessControlError, "Role #{role} must be present and must be a symbol!" if roles.any? { |r| !r.kind_of?(Symbol) } || roles.empty?
          raise Padrino::Admin::AccessControlError, "You can't merge :any with other roles" if roles.size > 1 && roles.any? { |r| r == :any }

          @roles += roles
          @authorizations << Authorization.new(*roles, &block)
        end

        ##
        # Return an array of roles
        #
        def roles
          @roles.uniq.reject { |r| r == :any }
        end

        ##
        # Return an array of project_modules
        #
        def project_modules(account)
          role = account.role.to_sym rescue :any
          authorizations = @authorizations.find_all { |auth| auth.roles.include?(role) }
          authorizations.map(&:project_modules).flatten.uniq
        end

        ##
        # Return true if the given account is allowed to see the given path.
        #
        # @example Hiding a disallowed link from a user
        #
        #     # File: config/apps.rb
        #     # [...]
        #     Padrino.mount('Admin').to('/admin')
        #
        #     # File: admin/app.rb
        #     class Admin < Padrino::Application
        #       # [...]
        #       register Padrino::Admin::AccessControl
        #       # [...]
        #
        #       # Goals:
        #       # * Admins can manage widgets and accounts
        #       # * Workers can only manage widgets
        #
        #       access_control.roles_for :admin do |role|
        #         role.project_module :accounts, '/accounts'
        #         role.project_module :widgets, '/widgets'
        #       end
        #
        #       access_control.roles_for :worker do |role|
        #         role.project_module :widgets, '/widgets'
        #       end
        #     end
        #
        #     # File: admin/views/layouts/application.haml
        #     # NOTE The un-mounted path is used ('/accounts' instead of '/admin/accounts')
        #     - if access_control.allowed?(current_account, '/accounts')
        #       # Admins see the "Profile" link, but Workers do not
        #       = link_to 'Profile', url(:accounts, :edit, :id => current_account.id)
        #
        def allowed?(account=nil, path=nil)
          path = "/" if path.blank?
          role = account.role.to_sym rescue nil
          authorizations = @authorizations.find_all { |auth| auth.roles.include?(:any) }
          allowed_paths  = authorizations.map(&:allowed).flatten.uniq
          denied_paths   = authorizations.map(&:denied).flatten.uniq
          if account
            denied_paths.clear
            # explicit authorizations for the role associated with the given account
            authorizations = @authorizations.find_all { |auth| auth.roles.include?(role) }
            allowed_paths += authorizations.map(&:allowed).flatten.uniq
            # other explicit authorizations
            authorizations = @authorizations.find_all { |auth| !auth.roles.include?(role) && !auth.roles.include?(:any) }
            denied_paths  += authorizations.map(&:allowed).flatten.uniq # remove paths explicitly allowed for other roles
            denied_paths  += authorizations.map(&:denied).flatten.uniq # remove paths explicitly denied to other roles
          end
          return true  if allowed_paths.any? { |p| path =~ /^#{p}/ }
          return false if denied_paths.any?  { |p| path =~ /^#{p}/ }
          true
        end
      end # Base

      ###
      # Project Authorization Class
      #
      class Authorization
        attr_reader :allowed, :denied, :project_modules, :roles

        def initialize(*roles, &block) # @private
          @roles           = roles
          @allowed         = []
          @denied          = []
          @project_modules = []
          yield self
        end

        ##
        # Allow a specified path
        #
        def allow(path)
          @allowed << path unless @allowed.include?(path)
        end

        ##
        # Protect access from
        #
        def protect(path)
          @denied << path unless @denied.include?(path)
        end

        ##
        # Create a project module
        #
        def project_module(name, path, options={})
          allow(path)
          @project_modules << ProjectModule.new(name, path, options)
        end
      end # Authorization

      ##
      # Project Module class
      #
      class ProjectModule
        attr_reader :name, :options

        def initialize(name, path, options={}) # @private
          @name, @path, @options = name, path, options
        end

        ##
        # Returns the name of the project module. If a symbol it translate/humanize them for you.
        #
        def human_name
          @name.is_a?(Symbol) ? I18n.t("padrino.admin.menu.#{@name}", :default => @name.to_s.humanize) : @name
        end

        ##
        # Return the path of the project module. If a prefix given will be prepended.
        #
        # @example
        #   # => /accounts/new
        #   project_module.path
        #   # => /admin/accounts
        #   project_module.path("/admin")
        #
        def path(prefix=nil)
          path = prefix ? File.join(prefix, @path) : @path
          path = File.join(ENV['RACK_BASE_URI'].to_s, path) if ENV['RACK_BASE_URI']
          path
        end

      end # ProjectModule
    end # AccessControl
  end # Admin
end # Padrino
