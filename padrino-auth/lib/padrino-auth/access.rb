require 'padrino-auth/permissions'

module Padrino
  # Padrino authorization module.
  module Access
    class << self
      def registered(app)
        included(app)
        deferred_permissions = app.method(:permissions) if app.respond_to?(:permissions)
        app.set :permissions, Permissions.new
        app.set :credentials_reader, :credentials unless app.respond_to?(:credentials_reader)
        app.send :attr_reader, app.credentials_reader unless app.instance_methods.include?(app.credentials_reader)
        app.reset_access!
        deferred_permissions.call if deferred_permissions.kind_of?(Method)
        app.before do
          access_action? or error(403, '403 Forbidden')
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
      def access_subject
        send settings.credentials_reader
      end

      def access_role?(*roles, &block)
        settings.permissions.check(access_subject, :have => roles, &block)
      end

      def access_action?(action = nil, object = nil, &block)
        object ||= request.controller.to_sym if request.controller
        action ||= request.action.to_sym if request.action
        granted = settings.permissions.check(access_subject, :allow => action, :with => object, &block)
        @access_requirements = { :subject => access_subject, :action => action, :object => object } unless granted
        granted
      end

      def access_object?(object = nil, action = nil, &block)
        allow_action action, object, &block
      end

      def access_objects(subject = access_subject)
        settings.permissions.find_objects(subject)
      end

      def authorized?
        access_action?
      end
    end
  end
end
