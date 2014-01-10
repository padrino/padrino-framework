require 'padrino-auth/permissions'

module Padrino
  # Padrino authorization module.
  module Access
    class << self
      def registered(app)
        included(app)
        app.set :permissions, Permissions.new
        app.default(:credentials_reader, :credentials)
        app.send :attr_reader, app.credentials_reader unless app.instance_methods.include?(app.credentials_reader)
        app.reset_access!
        app.login_permissions if app.respond_to?(:login_permissions)
        app.before do
          authorized? or error(403, '403 Forbidden')
        end
      end

      def included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      def reset_access!
        permissions.clear!
      end

      def set_access(*args)
        options = args.extract_options!
        options[:object] ||= Array(@_controller).first.to_s.singularize.to_sym if @_controller.present?
        permissions.add(*args, options)
      end
    end

    module InstanceMethods
      def authorized?
        access_action?
      end

      def access_subject
        send settings.credentials_reader
      end

      def access_role?(*roles, &block)
        settings.permissions.check(access_subject, :have => roles, &block)
      end

      def access_action?(action = nil, object = nil, &block)
        if respond_to?(:request)
          object ||= request.controller.to_s.to_sym
          action ||= request.action.to_s.to_sym
        end
        settings.permissions.check(access_subject, :allow => action, :with => object, &block)
      end

      def access_object?(object = nil, action = nil, &block)
        allow_action action, object, &block
      end

      def access_objects(subject = access_subject)
        settings.permissions.find_objects(subject)
      end
    end
  end
end
