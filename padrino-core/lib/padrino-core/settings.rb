module Padrino
  module Settings

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Sets an option to the given value.  If the value is a proc,
      # the proc will be called every time the option is accessed.
      def set(option, value = (not_set = true), ignore_setter = false, &block)
        raise ArgumentError if block and !not_set
        value, not_set = block, false if block

        if not_set
          raise ArgumentError unless option.respond_to?(:each)
          option.each { |k,v| set(k, v) }
          return self
        end

        if respond_to?("#{option}=") and not ignore_setter
          return __send__("#{option}=", value)
        end

        setter = -> val { set(option, val, true) }
        getter = -> { value }

        case value
        when Proc
          getter = value
        when Symbol, Fixnum, FalseClass, TrueClass, NilClass
          singleton_class.class_eval { define_method(option){ value } }
          getter = nil
        when Hash
          setter = proc do |val|
            val = value.merge val if Hash === val
            set option, val, true
          end
        end

        singleton_class.class_eval do
          define_method("#{option}=", &setter) if setter
          define_method(option, &getter) if getter
          define_method("#{option}?"){ !!send(option) } unless method_defined? "#{option}?"
        end

        self
      end

      # Same as calling `set :option, true` for each of the given options.
      def enable(*opts)
        opts.each { |key| set(key, true) }
      end

      # Same as calling `set :option, false` for each of the given options.
      def disable(*opts)
        opts.each { |key| set(key, false) }
      end

      def settings
        self
      end
    end

    def settings
      self.class.settings
    end
  end
end
