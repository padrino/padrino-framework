require 'padrino-core'

module Padrino
  ##
  # Role based access control for any Padrino app, without the admin.
  #
  # @example
  #     require 'padrino-admin/auth'
  #
  #     class App < Padrino::Application
  #       register Padrino::Auth
  #       enable :sessions
  #
  #       access_control.roles_for :any do |role|
  #         role.protect '/'
  #         role.allow '/login'
  #       end
  #
  #       # Optional: find the account another way than the session.
  #       current_account_from { Account.find_by_token(env['HTTP_X_TOKEN']) }
  #     end
  #
  # The padrino-admin AccessControl extension is the admin flavour: register it instead of this
  # one to also get project modules and the admin helpers.
  #
  module Auth
    ##
    # Raised for a misconfigured access control (bad roles, missing account model, bad hook result).
    #
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
      #    register Padrino::Auth
      #    # [...]
      #
      #    # Goals:
      #    # * Admins can manage widgets and accounts.
      #    # * Workers can only manage widgets.
      #
      #    access_control.roles_for :admin do |role|
      #      role.allow '/accounts'
      #      role.allow '/widgets'
      #    end
      #
      #    access_control.roles_for :worker do |role|
      #      role.allow '/widgets'
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

    ##
    # Common helpers used for authorization within an application.
    #
    module Helpers
      ##
      # Returns true if +current_account+ is logged and active.
      #
      def logged_in?
        !current_account.nil?
      end

      ##
      # Returns the current_account, it's an instance of Account model, or nil. It is looked up
      # once per request: with the block given to +current_account_from+ if the app has one,
      # else from the session.
      #
      def current_account
        return @current_account if defined?(@current_account)

        hook = self.class.respond_to?(:current_account_hook) && self.class.current_account_hook
        account = (hook ? instance_exec(&hook) : login_from_session) || nil
        if hook && account && !account.respond_to?(:role)
          raise Padrino::Auth::Error, "current_account_from must return an account (responding to role) or nil, got #{account.class}"
        end

        @current_account = account
      end

      ##
      # Override the current_account, you must provide an instance of Account model.
      #
      # When the logged-in account changes (logging in, logging out or switching accounts), the
      # session gets a new id and a new CSRF token, and keeps its other data. Logging out (no
      # account) removes this app's account key from the session.
      #
      # @example
      #     set_current_account(Account.authenticate(params[:email], params[:password])
      #
      def set_current_account(account = nil)
        account_id = account&.id
        # Compared as strings, so an id that the session coder stored as a string still matches.
        if session[settings.session_id].to_s != account_id.to_s
          if account_id.nil?
            session.delete(settings.session_id)
          else
            session[settings.session_id] = account_id
          end
          request.session_options[:renew] = true
          # Replaced rather than deleted, in the format Rack::Protection checks, so a form
          # rendered later in this request gets a token that is accepted.
          session[:csrf] = Rack::Protection::AuthenticityToken.random_token if session.key?(:csrf)
        end
        @current_account = account
      end

      ##
      # Returns true if the +current_account+ is allowed to see the requested path.
      #
      # For configure this role please refer to: +Padrino::Auth::Rules+
      #
      def allowed?
        access_control.allowed?(current_account, request.path_info)
      end

      ##
      # Returns a helper useful in a +before_filter+ for check if
      # an account are: +logged_in?+ and +allowed?+
      #
      # Registering Padrino::Auth adds it as a +before+ filter.
      #
      def login_required
        return if allowed?

        store_location! if store_location
        access_denied
      end

      ##
      # Store in session[:return_to] the path of the request (with SCRIPT_NAME and the query
      # string), under ENV['RACK_BASE_URI'] when that is set and the SCRIPT_NAME above the
      # app's mount point doesn't already start with it.
      #
      def store_location!
        path = request.fullpath
        base_uri = File.join('/', ENV['RACK_BASE_URI'].to_s).chomp('/')
        mount = settings.respond_to?(:uri_root) ? settings.uri_root.to_s.chomp('/') : ''
        outer_script_name = mount.empty? ? request.script_name : request.script_name.chomp(mount)
        unless base_uri.empty? || outer_script_name == base_uri || outer_script_name.start_with?("#{base_uri}/")
          path = File.join(base_uri, path)
        end
        session[:return_to] = path
      end

      ##
      # Redirect the account to the page that requested an authentication or
      # if the account is not allowed/logged return it to a default page.
      #
      # Only a path on this site is followed; anything else redirects to +default+.
      #
      def redirect_back_or_default(default)
        return_to = session.delete(:return_to)
        redirect(local_path?(return_to) ? return_to : default)
      end

      private

      def access_denied
        if login_page
          redirect url(login_page)
        else
          halt logged_in? ? 403 : 401, "You don't have permission for this resource"
        end
      end

      # One leading slash, not followed by another or by a backslash, and no control characters.
      LOCAL_PATH = %r{\A/(?![/\\])[^\x00-\x1f\x7f]*\z}n
      private_constant :LOCAL_PATH

      # True for a path on this site, checked as given and with its path part percent-decoded,
      # each as UTF-8 bytes.
      def local_path?(path)
        return false unless path.is_a?(String)

        bytes = path.b
        [bytes, Rack::Utils.unescape_path(bytes[/\A[^?#]*/n])].all? do |candidate|
          candidate.b.force_encoding(Encoding::UTF_8).valid_encoding? && candidate.b.match?(LOCAL_PATH)
        end
      end

      def login_page
        settings.respond_to?(:login_page) && settings.login_page
      end

      def store_location
        settings.respond_to?(:store_location) && settings.store_location
      end

      def login_from_session
        model = account_model_obj
        unless env.key?('rack.session')
          warn_missing_session
          return nil
        end

        model&.find_by_id(session[settings.session_id])
      end

      def warn_missing_session
        return if settings.instance_variable_get(:@_auth_session_warned)

        settings.instance_variable_set(:@_auth_session_warned, true)
        warn(<<~ERROR)
          Padrino::Auth looks up the current account in the session, but this app has no session. Use:

              enable :sessions

          or set current_account_from { ... } to find the account another way.
        ERROR
      end

      def account_model_obj
        @_account_model_obj ||= Padrino::Inflections.constantize(account_model_name)
      rescue NameError => e
        raise unless Padrino::Auth.missing_constant?(e, account_model_name)

        raise Padrino::Auth::Error, "You must define an #{account_model_name} Model"
      end

      def account_model_name
        settings.respond_to?(:admin_model) ? settings.admin_model : settings.account_model
      end
    end

    ##
    # Class methods added to an app by +setup+.
    #
    module ClassMethods
      ##
      # Chooses how the app finds the current account. The block runs in the request (it can call
      # +env+, +request+, +params+) once per request and returns an account that responds to
      # +role+, or nil. Without a block the account comes from the session.
      #
      # @example Find the account from a token header.
      #     current_account_from { Account.find_by_token(env['HTTP_AUTHORIZATION'].to_s[/\ABearer (.+)/, 1]) }
      #
      def current_account_from(&block)
        raise Padrino::Auth::Error, 'current_account_from needs a block' unless block

        @current_account_from = block
      end

      ##
      # The block given to +current_account_from+ on this app, or nil.
      #
      def current_account_hook
        @current_account_from
      end
    end

    class << self
      ##
      # Method used by Padrino::Application when we register the extension.
      #
      # A no-op when an extension that includes Auth (+includes_auth?+) is registered, or when the
      # app already registered Auth. Both checks read the extension list, which +reset!+ clears,
      # so a reloaded app sets up its rules and +before+ filter again.
      #
      def registered(app)
        return if app.extensions.any? { |e| e.respond_to?(:includes_auth?) && e.includes_auth? }
        return if app.instance_variable_get(:@extensions).count(Padrino::Auth) > 1

        setup(app, Padrino::Auth::Rules.new)
      end
      alias included registered

      ##
      # Shared setup for +register Padrino::Auth+ and the extensions built on it: session key,
      # account model, helpers, the one +before+ filter and the +access_control+ accessors. +rules+
      # becomes the app's +access_control+. Clears the +current_account_from+ hook, so a reloaded
      # app file without one finds the account in the session again.
      #
      def setup(app, rules)
        app.instance_variable_set(:@current_account_from, nil)
        app.set :session_id, "_padrino_#{Padrino.env}_#{app.app_name}" unless app.respond_to?(:session_id)
        app.set :account_model, 'Account' unless app.respond_to?(:account_model)
        app.helpers Padrino::Auth::Helpers
        app.extend Padrino::Auth::ClassMethods
        app.before { login_required }
        app.class_eval do
          class << self
            attr_accessor :access_control
          end

          def access_control
            self.class.access_control
          end
        end
        app.send(:access_control=, rules)
      end

      ##
      # Whether +error+, raised looking up the constant +name+, says that constant (or one of its
      # namespaces) is not defined, rather than coming from the code that defining it ran. The
      # error must name a segment of +name+ and have been raised on that segment's parent, so a
      # model whose body references another constant with the same short name isn't "missing".
      #
      def missing_constant?(error, name)
        return false unless error.instance_of?(NameError)

        segments = name.to_s.sub(/\A::/, '').split('::')
        return false unless error.receiver.is_a?(::Module)

        segments.each_index.any? do |index|
          parent = index.zero? ? 'Object' : segments.first(index).join('::')
          segments[index] == error.name.to_s && error.receiver.name == parent
        end
      rescue ArgumentError
        false
      end
    end
  end
end
