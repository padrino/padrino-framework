module Padrino
  module AccessControl
    module Helpers

      # Returns true if <tt>current_account</tt> is logged and active.
      def logged_in?
        !current_account.nil?
      end

      # Returns the current_account, it's an instance of <tt>Account</tt> model
      def current_account
        @current_account ||= login_from_session
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
        return false unless current_account
        maps = access_control.maps_for(current_account)
        maps.allowed.any? { |path| request.path_info =~ /^#{path}/ } && maps.denied.all? { |path| request.path_info !~ /^#{path}/ }
      end

      # Returns a helper to pass in a <tt>before_filter</tt> for check if
      # an account are: <tt>logged_in?</tt> and <tt>allowed?</tt>
      # 
      # By default this method is used in BackendController so is not necessary
      def login_required
        store_location if options.store_location
        return access_denied unless logged_in? && allowed?
      end

      def access_denied #:nodoc:
        if request.xhr?
          "alert('You don\'t have permission for this resource')"
        elsif options.redirect_failed_logins_to
          redirect(redirect_failed_logins_to)
        else
          halt 401, "You don't have permission for this resource"
        end
        false
      end

      def store_location #:nodoc:
        session[:return_to] = request.fullpath
      end

      # Redirect the account to the page that requested an authentication or
      # if the account is not allowed/logged return it to a default page
      def redirect_back_or_default(default)
        redirect_to(session[:return_to] || default)
        session[:return_to] = nil
      end

    private
      def session_name
        options.app_name.to_sym
      end

      def login_from_session #:nodoc:
        Account.find(session[session_name]) if session[session_name]
      rescue
        nil
      end
    end
  end
end