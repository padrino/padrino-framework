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
        # @example
        #     set_current_account(Account.authenticate(params[:email], params[:password])
        #
        def set_current_account(account=nil)
          session[settings.session_id] = account ? account.id : nil
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
          unless allowed?
            store_location! if store_location
            access_denied
          end
        end

        ##
        # Store in session[:return_to] the env['REQUEST_URI'].
        #
        def store_location!
          session[:return_to] = "#{ENV['RACK_BASE_URI']}#{env['REQUEST_URI']}" if env['REQUEST_URI']
        end

        ##
        # Redirect the account to the page that requested an authentication or
        # if the account is not allowed/logged return it to a default page.
        #
        def redirect_back_or_default(default)
          return_to = session.delete(:return_to)
          redirect(return_to || default)
        end

        private

        def access_denied
          if login_page
            redirect url(login_page)
          else
            halt 401, "You don't have permission for this resource"
          end
        end

        def login_page
          settings.respond_to?(:login_page) && settings.login_page
        end

        def store_location
          settings.respond_to?(:store_location) && settings.store_location
        end

        def login_from_session
          admin_model_obj.find_by_id(session[settings.session_id]) if admin_model_obj
        end

        def admin_model_obj
          @_admin_model_obj ||= settings.admin_model.constantize
        rescue NameError
          raise Padrino::Admin::AccessControlError, "You must define an #{settings.admin_model} Model"
        end
      end
    end
  end
end
