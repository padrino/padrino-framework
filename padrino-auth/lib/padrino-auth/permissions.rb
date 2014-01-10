module Padrino
  # Class to store and check permissions used in Padrino::Access.
  class Permissions
    def initialize
      clear!
    end

    def clear!
      @permits = {}
      @actions = {}
    end

    def add(*args)
      @actions = {}
      options = args.extract_options!
      action, object = action_and_object(options)
      object_type = detect_type(object)
      args.each{ |subject| merge(subject, action, object_type) }
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

    def merge(subject, action, object_type)
      subject_id = detect_id(subject)
      @permits[subject_id] ||= {}
      @permits[subject_id][action] ||= []
      @permits[subject_id][action] |= [object_type]
    end

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
      subject_id = detect_id(subject)
      return @actions[subject_id] if @actions[subject_id]
      actions = @permits[subject_id] || {}
      if subject.respond_to?(:role) && (role_actions = @permits[subject.role.to_sym])
        actions.merge!(role_actions){ |_,left,right| Array(left)|Array(right) }
      end
      if public_actions = @permits[:*]
        actions.merge!(public_actions){ |_,left,right| Array(left)|Array(right) }
      end
      @actions[subject_id] = actions
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
