require 'ostruct'
require 'padrino-auth/login/controller'

module Padrino
  ##
  # Padrino authentication module.
  #
  # @example
  #   class Nifty::Application < Padrino::Application
  #     # optional settings
  #     set :session_id, "visitor_id"       # visitor key name in session storage, defaults to "_login_#{app.app_name}")
  #     set :login_model, :visitor          # model name for visitor storage, defaults to :account, must be constantizable
  #     set :credentials_accessor, :visitor # the name of setter/getter method in helpers, defaults to :credentials
  #     enable :login_bypass                # enables or disables login bypass in development mode, defaults to disable
  #     set :login_url, '/sign/in'          # sets the utl to be redirected to if not logged in and in restricted area, defaults to '/login'
  #     disable :login_permissions          # sets initial login permissions, defaults to { set_access(:*, :allow => :*, :with => :login) }
  #     disable :login_controller           # disables default login controller to show an example of the custom one
  #
  #     # required statement
  #     register Padrino::Login
  #     # example persistance storage
  #     enable :sessions
  #   end
  #
  #   TODO: example controllers
  #
  module Login
    class << self
      def registered(app)
        fail 'Padrino::Login must be registered before Padrino::Access' if app.respond_to?(:set_access)
        included(app)
        setup_storage(app)
        setup_controller(app)
        app.before do
          log_in if authorization_required?
        end
      end

      def included(base)
        base.send(:include, InstanceMethods)
      end

      private

      def setup_storage(app)
        app.default(:session_id, "_login_#{app.app_name}")
        app.default(:login_model, :account)
        app.default(:credentials_accessor, :credentials)
        app.send :attr_reader, app.credentials_accessor unless app.instance_methods.include?(app.credentials_accessor)
        app.send :attr_writer, app.credentials_accessor unless app.instance_methods.include?(:"#{app.credentials_accessor}=")
        app.default(:login_bypass, false)
      end

      def setup_controller(app)
        app.default(:login_url, '/login')
        app.default(:login_permissions) { set_access(:*, :allow => :*, :with => :login) }
        app.default(:login_controller, true)
        app.controller(:login) { include Controller } if app.login_controller
      end
    end

    module InstanceMethods
      def login_model
        @login_model ||= settings.login_model.to_s.classify.constantize
      end

      def authenticate
        resource = login_model.authenticate(:email => params[:email], :password => params[:password])
        resource ||= login_model.authenticate(:bypass => true) if settings.login_bypass && params[:bypass]
        save_credentials(resource)
      end

      def logged_in?
        !!(send(settings.credentials_accessor) || restore_credentials)
      end

      def unauthorized?
        respond_to?(:authorized?) && !authorized?
      end

      def authorization_required?
        if logged_in?
          if unauthorized?
            # 403 Forbidden, provided credentials were successfully
            # authenticated but the credentials still do not grant
            # the client permission to access the resource
            error 403
          else
            false
          end
        else
          unauthorized?
        end
      end

      def log_in
        login_url = settings.login_url
        if request.env['PATH_INFO'] != login_url
          save_location
          # 302 Found
          redirect url(login_url) 
          # 401 Unauthorized, authentication is required and
          # has not yet been provided
          error 401, '401 Unauthorized'
        end
      end

      def save_credentials(resource)
        session[settings.session_id] = resource.respond_to?(:id) ? resource.id : resource
        send(:"#{settings.credentials_accessor}=", resource)
      end

      def restore_credentials
        resource = login_model.authenticate(:session_id => session[settings.session_id])
        send(:"#{settings.credentials_accessor}=", resource)
      end

      def restore_location
        redirect session.delete(:return_to) || url('/')
      end

      def save_location
        uri = env['REQUEST_URI'] || url(env['PATH_INFO'])
        return if uri.blank? || uri.match(/\.css$|\.js$|\.png$/)
        session[:return_to] = "#{ENV['RACK_BASE_URI']}#{uri}"
      end
    end
  end
end
