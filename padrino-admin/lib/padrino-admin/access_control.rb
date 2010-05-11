module Padrino
  module Admin
    class AccessControlError < StandardError #:nodoc:
    end
    ##
    # This module give to a padrino application an access control functionality
    #
    module AccessControl
      ##
      # Method used by Padrino::Application when we register the extension
      #
      def self.registered(app)
        app.set :session_id, "_padrino_#{File.basename(Padrino.root)}_#{app.app_name}".to_sym
        app.enable :sessions
        app.helpers Padrino::Admin::Helpers::AuthenticationHelpers
        app.helpers Padrino::Admin::Helpers::ViewHelpers
        app.before { login_required }
        app.extend(ClassMethods)
        app.send(:cattr_accessor, :access_control)
        app.send(:access_control=, Padrino::Admin::AccessControl::Base.new)
        app.class_eval { class << self; alias_method_chain :reload!, :access_control; end }
      end

      module ClassMethods #:nodoc:
        def reload_with_access_control!
          self.access_control = Padrino::Admin::AccessControl::Base.new
          reload_without_access_control!
        end
      end

      class Base
        def initialize #:nodoc:
          @roles, @authorizations, @project_modules = [], [], []
        end
        ##
        # We map project modules for a given role or roles
        #
        def roles_for(*roles, &block)
          raise Padrino::Admin::AccessControlError, "You must define an Account Model!" unless defined?(Account)
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
          authorizations.collect(&:project_modules).flatten.uniq
        end

        ##
        # Return true if the given account is allowed to see the given path.
        #
        def allowed?(account=nil, path=nil)
          path = "/" if path.blank?
          role = account.role.to_sym rescue nil
          authorizations = @authorizations.find_all { |auth| auth.roles.include?(:any) }
          allowed_paths  = authorizations.collect(&:allowed).flatten.uniq
          denied_paths   = authorizations.collect(&:denied).flatten.uniq
          if account
            denied_paths.clear
            authorizations = @authorizations.find_all { |auth| auth.roles.include?(role) }
            allowed_paths += authorizations.collect(&:allowed).flatten.uniq
            authorizations = @authorizations.find_all { |auth| !auth.roles.include?(role) && !auth.roles.include?(:any) }
            denied_paths  += authorizations.collect(&:allowed).flatten.uniq
            denied_paths  += authorizations.collect(&:denied).flatten.uniq
          end
          return true  if allowed_paths.any? { |p| path =~ /^#{p}/ }
          return false if denied_paths.any?  { |p| path =~ /^#{p}/ }
          true
        end
      end # Base

      class Authorization
        attr_reader :allowed, :denied, :project_modules, :roles

        def initialize(*roles, &block) #:nodoc:
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
        def project_module(name, path)
          allow(path)
          @project_modules << ProjectModule.new(name, path)
        end
      end # Authorization

      ##
      # Project Module class
      #
      class ProjectModule
        attr_reader :name

        def initialize(name, path) #:nodoc:
          @name, @path = name, path
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
        # ==== Examples
        #
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