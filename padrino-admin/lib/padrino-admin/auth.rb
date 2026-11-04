require 'padrino-core'

module Padrino
  module Auth
    class Error < StandardError
    end

    ##
    # Role based path rules: roles are defined, each with the paths it allows and protects.
    #
    class Rules
      # How many forms of a request path deny Regexps are checked against at most; a path with more
      # is denied (deny_forms).
      MAX_DENY_FORMS = 64

      def initialize
        @roles, @authorizations = [], []
      end

      ##
      # We map paths for a given role or roles.
      #
      def roles_for(*roles, &block)
        raise Padrino::Auth::Error, "Role #{roles.inspect} must be present and must be a symbol!" if roles.any? { |r| !r.is_a?(Symbol) } || roles.empty?
        raise Padrino::Auth::Error, "You can't merge :any with other roles" if roles.size > 1 && roles.any? { |r| r == :any }

        @roles += roles
        @authorizations << authorization_class.new(*roles, &block)
      end

      ##
      # Return an array of roles.
      #
      def roles
        @roles.uniq.reject { |r| r == :any }
      end

      ##
      # Return true if the given account is allowed to see the given path.
      #
      # @example Hiding a disallowed link from a user.
      #
      #  # File: config/apps.rb
      #  # [...]
      #  Padrino.mount('Admin').to('/admin')
      #
      #  # File: admin/app.rb
      #  class Admin < Padrino::Application
      #    # [...]
      #    register Padrino::Admin::AccessControl
      #    # [...]
      #
      #    # Goals:
      #    # * Admins can manage widgets and accounts.
      #    # * Workers can only manage widgets.
      #
      #    access_control.roles_for :admin do |role|
      #      role.project_module :accounts, '/accounts'
      #      role.project_module :widgets, '/widgets'
      #    end
      #
      #    access_control.roles_for :worker do |role|
      #      role.project_module :widgets, '/widgets'
      #    end
      #  end
      #
      #  # File: admin/views/layouts/application.haml
      #  # NOTE The un-mounted path is used ('/accounts' instead of '/admin/accounts')
      #  - if access_control.allowed?(current_account, '/accounts')
      #    # Admins see the "Profile" link, but Workers do not
      #    = link_to 'Profile', url(:accounts, :edit, id: current_account.id)
      #
      def allowed?(account = nil, path = nil)
        path = '/' if path.nil? || path.empty?
        # Allow rules see the decoded path the router matches ('%2F' stays inside its segment); deny
        # rules see every form the router may serve it as (deny_forms).
        paths = Padrino::Routing.path_forms(path)
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
        # A path with a newline satisfies no allow rule.
        return denied_paths.empty? if paths.any? { |form| form.include?("\n") }
        return true  if allowed_paths.any? { |p| path_within?(paths.first, p) }
        return true  if denied_paths.empty?

        forms = denied_paths.any?(Regexp) ? deny_forms(paths) : paths
        return false unless forms
        return false if denied_paths.any? { |p| forms.any? { |form| form.start_with?(p) } } # loose on purpose: fails closed
        true
      end

      protected

      def authorization_class
        Padrino::Auth::Authorization
      end

      private

      # The forms of the path (Routing.path_forms), without its trailing slashes, and without a
      # format after a dot of its last segment, as a route may serve any of those ('/billing.json'
      # and '/billing/' from '/billing'). Other delimiters start a different page ('/billing-day').
      # A String rule needs none of them: each is a prefix of a decoded form, which start_with?
      # already covers. Returns nil for a path with more than MAX_DENY_FORMS forms, so that it is
      # denied rather than checked in part.
      def deny_forms(paths)
        forms = Padrino::Routing.served_forms(paths).first(MAX_DENY_FORMS + 1)
        forms unless forms.size > MAX_DENY_FORMS
      end

      # An allowed path covers itself, its sub-paths and its formats ('/posts' allows '/posts',
      # '/posts/1' and '/posts.json'), but not unrelated paths that merely start with it ('/posts_admin').
      # A Regexp matches at the start of the path, as on the deny side.
      def path_within?(path, prefix)
        return path.start_with?(prefix) if prefix.is_a?(Regexp) || prefix.end_with?('/', '.')

        path == prefix || path.start_with?("#{prefix}/", "#{prefix}.")
      end
    end

    ###
    # Project Authorization Class.
    #
    class Authorization
      attr_reader :allowed, :denied, :roles

      def initialize(*roles, &block)
        @roles   = roles
        @allowed = []
        @denied  = []
        yield self
      end

      ##
      # Allow a specified path.
      #
      def allow(path)
        @allowed << path unless @allowed.include?(path)
      end

      ##
      # Protect access from.
      #
      def protect(path)
        @denied << path unless @denied.include?(path)
      end
    end
  end
end
