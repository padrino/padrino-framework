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
  end
end

## Hash#slice, Hash#slice!
unless Hash.method_defined?(:slice)
  require 'extlib/hash'
  class Hash
    def slice(*keys)
      keys = keys.map! { |key| convert_key(key) } if respond_to?(:convert_key)
      hash = self.class.new
      keys.each { |k| hash[k] = self[k] if has_key?(k) }
      hash
    end
  end
end

## Hash#to_params
unless Hash.method_defined?(:to_params)
  require 'extlib/hash'
end

## Hash#reverse_merge, Hash#reverse_merge!
unless Hash.method_defined?(:present?)
  class Hash
    def reverse_merge(other_hash)
      other_hash.merge(self)
    end

    def reverse_merge!(other_hash)
      replace(reverse_merge(other_hash))
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
unless Array.method_defined?(:blank?)
  require 'extlib/blank'
end

## Object#present?
unless Array.method_defined?(:present?)
  class Object
    def present?
      !blank?
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
