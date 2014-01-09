module Padrino
  class Permissions
    def initialize
      clear!
    end

    def clear!
      @permits = {}
      @actions = {}
    end

    def add(*args)
      options = args.extract_options!
      action, object = action_and_object(options)
      object_type = detect_type(object)
      @actions = {}
      args.each do |subject|
        id = detect_id(subject)
        @permits[id] ||= {}
        @permits[id][action] ||= []
        @permits[id][action] |= [object_type]
      end
    end

    def check(subject, options)
      case
      when options[:have]
        check_role(subject, options[:have])
      when options[:url]
        fail NotImplementedError
      else
        check_action(subject, *action_and_object(options))
      end && (block_given? ? yield : true)
    end

    def find_objects(subject)
      find_actions(subject).inject([]) do |all,(action,objects)|
        all |= objects
      end
    end

    if Padrino.env != :production
      def list; @permits; end
    end

    private

    def check_role(subject, roles)
      if subject.respond_to?(:role)
        Array(roles).include?(subject.role)
      else
        false
      end
    end

    def check_action(subject, action, object)
      actions = find_actions(subject)
      objects = actions && (actions[action] || actions[:*])
      objects && (objects & [:*, detect_type(object)]).any?
    end

    def find_actions(subject)
      id = detect_id(subject)
      return @actions[id] if @actions[id]
      actions = @permits[id] || {}
      if subject.respond_to?(:role) && (role_actions = @permits[subject.role.to_sym])
        actions.merge!(role_actions){ |_,a,b| Array(a)|Array(b) }
      end
      if public_actions = @permits[:*]
        actions.merge!(public_actions){ |_,a,b| Array(a)|Array(b) }
      end
      @actions[id] = actions
    end

    def detect_type(object)
      case object
      when Symbol
        object.to_s.singularize.to_sym
      when Proc
        NotImplementedError
      else
        object
      end
    end

    def detect_id(subject)
      case
      when Symbol === subject
        subject
      when subject.respond_to?(:to_param)
        subject.to_param
      when subject.respond_to?(:id)
        subject.id.to_s
      else
        "#{subject}"
      end
    end

    def action_and_object(options)
      [options[:allow] || options[:action] || :*, options[:with] || options[:object] || :*]
    end
  end
end
