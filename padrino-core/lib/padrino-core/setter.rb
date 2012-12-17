module Padrino
  module Setter
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

      setter = proc { |val| set option, val, true }
      getter = proc { value }

      case value
      when Proc
        getter = value
      when Symbol, Fixnum, FalseClass, TrueClass, NilClass
        # we have a lot of enable and disable calls, let's optimize those
        class_eval "def self.#{option}() #{value.inspect} end"
        getter = nil
      when Hash
        setter = proc do |val|
          val = value.merge val if Hash === val
          set option, val, true
        end
      end

      (class << self; self; end).class_eval do
        define_method("#{option}=", &setter) if setter
        define_method(option,       &getter) if getter
        unless method_defined? "#{option}?"
          class_eval "def #{option}?() !!#{option} end"
        end
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
  end
end
