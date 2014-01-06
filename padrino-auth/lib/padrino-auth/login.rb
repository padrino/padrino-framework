require 'ostruct'
require 'padrino-auth/login/controller'

module Padrino
  # Padrino authentication module.
  module Login
    class << self
      def set_defaults(app)
        app.set :session_id, app.app_name.to_sym unless app.respond_to?(:session_id)
        app.set :access_subject, :credentials    unless app.respond_to?(:access_subject)
        app.set :login_url, '/login'             unless app.respond_to?(:login_url)
        app.set :login_model, :account           unless app.respond_to?(:login_model)
        app.disable :login_bypass                unless app.respond_to?(:login_bypass)
      end

      def registered(app)
        included(app)
        set_defaults(app)
        app.before do
          log_in if authorization_required?
        end
        app.controller :login do
          include Controller
        end
      end

      def included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods

      private

    end

    module InstanceMethods
      def login_model
        @login_model ||= settings.login_model.to_s.classify.constantize
      end

      def authenticate
        @credentials = login_model.authenticate(:email => params[:email], :password => params[:password])
        @credentials ||= login_model.authenticate(:bypass => true) if settings.login_bypass && params[:bypass]
        save_credentials
      end

      def credentials
        @credentials || OpenStruct.new(:role => :guest)
      end

      def logged_in?
        restore_credentials
        !!@credentials
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
          true
        end
      end

      def log_in
        login_url = settings.login_url
        if request.env['PATH_INFO'] != login_url
          save_location
          # 302 Found
          redirect url(login_url) 
          message = settings.respond_to?(:permissions) ? settings.permissions.list.inspect : '401 Unauthorized'
          # 401 Unauthorized, authentication is required and
          # has not yet been provided
          error 401, message
        end
      end

      def save_credentials
        session[settings.session_id] = @credentials.id if @credentials
      end

      def restore_credentials
        resource = login_model.authenticate(:session_id => session[settings.session_id])
        @credentials = resource if resource
      end

      def restore_location
        redirect session.delete(:return_to) || url('/')
      end

      def save_location
        uri = request.env['REQUEST_URI'].to_s
        p "wanna save #{uri}"
        return if uri.blank? || uri.match(/\.css$|\.js$|\.png$/)
        session[:return_to] = "#{ENV['RACK_BASE_URI']}#{uri}"
      rescue => e
        fail "saving session[:return_to] failed because of #{e.class}: #{e.message}"
      end
    end
  end
end
