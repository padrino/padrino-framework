module Padrino
  ##
  # Class to store and check permissions used in Padrino::Access.
  #
  class Permissions
    ##
    # Initializes new permissions storage.
    #
    # @example
    #   permissions = Permissions.new
    #
    def initialize
      clear!
    end

    ##
    # Clears permit records and action cache.
    #
    # @example
    #   permissions.clear!
    #
    def clear!
      @permits = {}
      @actions = {}
    end

    ##
    # Adds a permission record to storage.
    #
    # @param [Symbol || Object] subject
    #   permit subject
    # @param [Hash] options
    #   permit attributes
    # @param [Symbol] options[:allow] || options[:action]
    #   what action to allow with objects
    # @param [Symbol] options[:with] || options[:object]
    #   with what objects allow specified action
    #
    # @example
    #   permissions.add :robots, :allow => :protect, :object => :humans
    #   permissions.add @bender, :allow => :kill, :object => :humans
    #
    def add(*args)
      @actions = {}
      options = args.extract_options!
      action, object = action_and_object(options)
      object_type = detect_type(object)
      args.each{ |subject| merge(subject, action, object_type) }
    end

    ##
    # Checks if permission record exists. Returns a boolean or yield a block.
    #
    # @param [Object] subject
    #   performer of an action
    # @param [Hash] options
    #   attributes to check
    # @param [Symbol] options[:have]
    #   check if the subject has a role
    # @param [Symbol] options[:allow] || options[:action]
    #   check if the subject is allowed to perform the action
    # @param [Symbol] options[:with] || options[:object]
    #   check if the subject is allowed to interact with the subject
    # @param [Proc]
    #   optional block to yield if the action is allowed
    #
    # @example
    #   # check if @bender have role :robots
    #   permissions.check @bender, :have => :robots # => true
    #   # check if @bender is allowed to kill :humans
    #   permissions.check @bender, :allow => :kill, :object => :humans # => true
    #   # check if @bender is allowed to kill :humans and yield a block
    #   permissions.check @bender, :allow => :kill, :object => :humans do
    #     @bender.kill_all! :humans
    #   end
    #
    def check(subject, options)
      case
      when options[:have]
        check_role(subject, options[:have])
      else
        check_action(subject, *action_and_object(options))
      end && (block_given? ? yield : true)
    end

    ##
    # Populates and returns the list of objects available to the subject.
    #
    # @param [Object] subject
    #   the subject to be checked for actions
    #
    def find_objects(subject)
      find_actions(subject).inject([]) do |all,(action,objects)|
        all |= objects
      end
    end

    private

    # Merges a list of new permits into permissions storage.
    def merge(subject, action, object_type)
      subject_id = detect_id(subject)
      @permits[subject_id] ||= {}
      @permits[subject_id][action] ||= []
      @permits[subject_id][action] |= [object_type]
    end

    # Checks if the subject has the role.
    def check_role(subject, roles)
      if subject.respond_to?(:role)
        Array(roles).include?(subject.role)
      else
        false
      end
    end

    # Checks if the subject is allowed to perform the action with the object.
    def check_action(subject, action, object)
      actions = find_actions(subject)
      objects = actions && (actions[action] || actions[:*])
      objects && (objects & [:*, detect_type(object)]).any?
    end

    # Finds all permits for the subject. Caches the permits in @actions.
    #   find_actions(@bender) # => { :kill => { :humans }, :drink => { :booze }, :* => { :login } }
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

    # Returns object type.
    #   detect_type :humans # => :human
    #   detect_type 'foobar' # => 'foobar'
    def detect_type(object)
      case object
      when Symbol
        object.to_s.singularize.to_sym
      else
        object
      end
    end

    # Returns parametrized subject.
    #   detect_id :robots               # => :robots
    #   detect_id sluggable_ar_resource # => 'Sluggable-resource-slug'
    #   detect_id some_resource_with_id # => '4'
    #   detect_id generic_object        # => "<Object:0x00001234>"
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

    # Utility function to extract action and object from options. Defaults to [:*, :*]
    #   action_and_object(:allow => :kill, :object => :humans)    # => [:kill, :humans]
    #   action_and_object(:action => :romance, :with => :mutants) # => [:romance, :mutants]
    #   action_and_object({})                                     # => [:*, :*]
    def action_and_object(options)
      [options[:allow] || options[:action] || :*, options[:with] || options[:object] || :*]
    end
  end
end
