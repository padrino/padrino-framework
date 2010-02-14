module Padrino
  module Admin
    module Helpers
      module AuthenticationHelpers
        ##
        # Returns true if +current_account+ is logged and active.
        # 
        def logged_in?
          !current_account.nil?
        end

        ##
        # Returns the current_account, it's an instance of <tt>Account</tt> model
        # 
        def current_account
          @current_account ||= login_from_session
        end

        ##
        #  Return the admin menu
        # 
        def admin_menu
          return "[]" unless current_account
          access_control.auths(current_account).project_modules.collect(&:config).to_json
        end

        ##
        # Ovverride the current_account, you must provide an instance of Account Model
        # 
        # ==== Examples:
        # 
        #     set_current_account(Account.authenticate(params[:email], params[:password])
        # 
        def set_current_account(account=nil)
          session[options.session_id] = account ? account.id : nil
          @current_account = account
        end

        ##
        # Returns true if the +current_account+ is allowed to see the requested path
        # 
        # For configure this role please refer to: +Padrino::Admin::AccessControl::Base+
        # 
        def allowed?
          access_control.auths(current_account).can?(request.path_info)
        end

        ##
        # Returns a helper useful in a +before_filter+ for check if
        # an account are: +logged_in?+ and +allowed?+
        # 
        # By default this method is used in Admin Apps.
        # 
        def login_required
          store_location! if store_location
          return access_denied unless allowed?
        end

        ##
        # Store in session[:return_to] the env['HTTP_REFERER']
        # 
        def store_location!
          session[:return_to] = env['HTTP_REFERER']
        end

        ##
        # Redirect the account to the page that requested an authentication or
        # if the account is not allowed/logged return it to a default page
        # 
        def redirect_back_or_default(default)
          return_to = session.delete(:return_to)
          redirect(return_to || default)
        end

        private
          def access_denied
            # If request a javascript we alert the user
            if request.xhr? || content_type == :js
              halt 401, "alert('Protected resource')"
            # If we have a login_page we redirect the user
            elsif login_page
              redirect(login_page)
            # If no match we halt with 401
            else
              halt 401, "You don't have permission for this resource"
            end
          end

          def login_page
            options.login_page rescue nil # on sinatra 9.4.x respond_to?(:login_page) didn't work
          end

          def store_location
            options.store_location rescue false
          end

          def login_from_session
            Account.first(:conditions => { :id => session[options.session_id] }) if defined?(Account)
          end
      end # AuthenticationHelpers
    end # Helpers
  end # Admin
end # Padrino