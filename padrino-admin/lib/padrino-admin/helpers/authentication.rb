module Padrino
  module Admin
    module Helpers
      # Returns true if <tt>current_account</tt> is logged and active.
      def logged_in?
        !current_account.nil?
      end

      # Returns the current_account, it's an instance of <tt>Account</tt> model
      def current_account
        @current_account ||= login_from_session
      end

      # Return the admin menu
      def admin_menu
        return "[]" unless current_account
        access_control.auths(current_account).project_modules.collect(&:config).to_json
      end

      # Ovverride the current_account, you must provide an instance of Account Model
      # 
      #   Examples:
      #   
      #     current_account = Account.last
      # 
      def set_current_account(account)
        session[session_name] = account.id rescue nil
        @current_account      = account
      end

      # Returns true if the <tt>current_account</tt> is allowed to see the requested path
      # 
      # For configure this role please refer to: <tt>Padrino::AccessControl::Base</tt>
      def allowed?
        access_control.auths(current_account).can?(request.path_info)
      end

      # Returns a helper to pass in a <tt>before_filter</tt> for check if
      # an account are: <tt>logged_in?</tt> and <tt>allowed?</tt>
      # 
      # By default this method is used in BackendController so is not necessary
      def login_required
        store_location! if store_location
        return access_denied unless allowed?
      end

      # Store in session[:return_to] the request.fullpath
      def store_location!
        session[:return_to] = request.fullpath
      end

      # Redirect the account to the page that requested an authentication or
      # if the account is not allowed/logged return it to a default page
      def redirect_back_or_default(default)
        redirect_to(session[:return_to] || default)
        session[:return_to] = nil
      end

    private
      def access_denied #:nodoc:
        # If request a javascript we alert the user
        if request.xhr?
          "alert('You don\'t have permission for this resource')"
        # If we have a login_page we redirect the user
        elsif login_page
          redirect(login_page)
        # If no match we halt with 401
        else
          halt 401, "You don't have permission for this resource"
        end
        false
      end

      def login_page
        options.login_page rescue nil # for some reason on sinatra 9.4.x respond_to?(:login_page) didn't work
      end

      def store_location
        options.store_location rescue false
      end

      def session_name
        options.app_name.to_sym
      end

      def login_from_session #:nodoc:
        Account.first(:conditions => { :id => session[session_name] }) if defined?(Account)
      end
    end
  end
end