# This helps extlib to act like ActiveSupport for use with Padrino

## Class#cattr_accessor
unless Class.method_defined?(:cattr_accessor)
  require 'extlib/class'
end

## SupportLite::OrderedHash
unless defined?(SupportLite::OrderedHash)
  require 'extlib/dictionary'
  module SupportLite
    OrderedHash = ::Dictionary
  end
end

## Hash#symbolize_keys
unless Hash.method_defined?(:symbolize_keys)
  require 'extlib/hash'
  require 'extlib/mash'
  class Hash
    def symbolize_keys
      Mash.new(self).symbolize_keys
    end

    def symbolize_keys!
      self.replace(symbolize_keys.to_hash)
    end
  end
end

## Hash#slice, Hash#slice!
unless Hash.method_defined?(:slice)
  require 'extlib/hash'
  class Hash
    # Slice a hash to include only the given keys. This is useful for
    # limiting an options hash to valid keys before passing to a method:
    #
    #   def search(criteria = {})
    #     assert_valid_keys(:mass, :velocity, :time)
    #   end
    #
    #   search(options.slice(:mass, :velocity, :time))
    #
    # If you have an array of keys you want to limit to, you should splat them:
    #
    #   valid_keys = [:mass, :velocity, :time]
    #   search(options.slice(*valid_keys))
    def slice(*keys)
      keys = keys.map! { |key| convert_key(key) } if respond_to?(:convert_key)
      hash = self.class.new
      keys.each { |k| hash[k] = self[k] if has_key?(k) }
      hash
    end

    # Replaces the hash with only the given keys.
    # Returns a hash contained the removed key/value pairs
    #   {:a => 1, :b => 2, :c => 3, :d => 4}.slice!(:a, :b) # => {:c => 3, :d =>4}
    def slice!(*keys)
      keys = keys.map! { |key| convert_key(key) } if respond_to?(:convert_key)
      omit = slice(*self.keys - keys)
      hash = slice(*keys)
      replace(hash)
      omit
    end
  end
end

## Hash#to_params
unless Hash.method_defined?(:to_params)
  require 'extlib/hash'
end

## Hash#reverse_merge, Hash#reverse_merge!
unless Hash.method_defined?(:reverse_merge)
  class Hash
    def reverse_merge(other_hash)
      other_hash.merge(self)
    end

    def reverse_merge!(other_hash)
      replace(reverse_merge(other_hash))
    end

    def deep_merge(other_hash)
      target = dup
      other_hash.each_pair do |k,v|
        tv = target[k]
        target[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? tv.deep_merge(v) : v
      end
      target
    end
  end
end

## Array#extract_options!
unless Array.method_defined?(:extract_options!)
  class Array
    def extract_options!
      last.is_a?(::Hash) ? pop : {}
    end
  end
end

## String#inflectors
unless String.method_defined?(:constantize)
  require 'extlib/inflection'
  class String
    def classify;    Extlib::Inflection.classify(self);    end
    def underscore;  Extlib::Inflection.underscore(self);  end
    def constantize; Extlib::Inflection.constantize(self); end
    def camelize;    Extlib::Inflection.camelize(self);    end
    def humanize;    Extlib::Inflection.humanize(self);    end
    alias :titleize :humanize
  end
end

## Object#blank?
unless Object.method_defined?(:blank?)
  require 'extlib/blank'
end

## Object#present?
unless Object.method_defined?(:present?)
  class Object
    def present?
      !blank?
    end
  end
end

## Object#with_options
unless Object.method_defined?(:with_options)
  class SupportLite::OptionMerger #:nodoc:
    instance_methods.each do |method|
      undef_method(method) if method !~ /^(__|instance_eval|class|object_id)/
    end

    def initialize(context, options)
      @context, @options = context, options
    end

    private
      def method_missing(method, *arguments, &block)
        if arguments.last.is_a?(Proc)
          proc = arguments.pop
          arguments << lambda { |*args| @options.deep_merge(proc.call(*args)) }
        else
          arguments << (arguments.last.respond_to?(:to_hash) ? @options.deep_merge(arguments.pop) : @options.dup)
        end

        @context.__send__(method, *arguments, &block)
      end
  end

  class Object
    def with_options(options)
      yield SupportLite::OptionMerger.new(self, options)
    end
  end
end

## Module#alias_method_chain
unless Module.method_defined?(:alias_method_chain)
  def alias_method_chain(target, feature)
    # Strip out punctuation on predicates or bang methods since
    # e.g. target?_without_feature is not a valid method name.
    aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
    yield(aliased_target, punctuation) if block_given?

    with_method, without_method = "#{aliased_target}_with_#{feature}#{punctuation}", "#{aliased_target}_without_#{feature}#{punctuation}"

    alias_method without_method, target
    alias_method target, with_method

    case
      when public_method_defined?(without_method)
        public target
      when protected_method_defined?(without_method)
        protected target
      when private_method_defined?(without_method)
        private target
    end
  end
end
