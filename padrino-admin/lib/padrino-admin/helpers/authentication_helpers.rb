module Padrino
  module Admin
    module Helpers
      ##
      # Common helpers used for authorization within an application.
      #
      module AuthenticationHelpers
        ##
        # Returns true if +current_account+ is logged and active.
        #
        def logged_in?
          !current_account.nil?
        end

        ##
        # Returns the current_account, it's an instance of Account model.
        #
        def current_account
          @current_account ||= login_from_session
        end

        ##
        # Override the current_account, you must provide an instance of Account model.
        #
        # When the logged-in account changes (logging in, logging out or switching accounts), the
        # session gets a new id and keeps its other data. Logging out (no account) removes this
        # app's account key from the session.
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
          end
          @current_account = account
        end

        ##
        # Returns true if the +current_account+ is allowed to see the requested path.
        #
        # For configure this role please refer to: +Padrino::Admin::AccessControl::Base+
        #
        def allowed?
          access_control.allowed?(current_account, request.path_info)
        end

        ##
        # Returns project modules for the current account.
        #
        def project_modules
          access_control.project_modules(current_account)
        end

        ##
        # Returns a helper useful in a +before_filter+ for check if
        # an account are: +logged_in?+ and +allowed?+
        #
        # By default this method is used in Admin Apps.
        #
        def login_required
          return if allowed?

          store_location! if store_location
          access_denied
        end

        ##
        # Store in session[:return_to] the path of the request, with its query string,
        # under ENV['RACK_BASE_URI'] when that is set.
        #
        def store_location!
          path = request.fullpath
          session[:return_to] = ENV['RACK_BASE_URI'] ? File.join(ENV['RACK_BASE_URI'], path) : path
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

        # True for a path on this site, checked as given and with its path part percent-decoded.
        def local_path?(path)
          return false unless path.is_a?(String)

          [path, Rack::Utils.unescape_path(path[/\A[^?#]*/])].all? { |candidate| candidate.b.match?(LOCAL_PATH) }
        end

        def login_page
          settings.respond_to?(:login_page) && settings.login_page
        end

        def store_location
          settings.respond_to?(:store_location) && settings.store_location
        end

        def login_from_session
          admin_model_obj&.find_by_id(session[settings.session_id])
        end

        def admin_model_obj
          @_admin_model_obj ||= Padrino::Inflections.constantize(settings.admin_model)
        rescue NameError => e
          raise unless Padrino::Admin.missing_constant?(e, settings.admin_model)

          raise Padrino::Admin::AccessControlError, "You must define an #{settings.admin_model} Model"
        end
      end
    end
  end
end
