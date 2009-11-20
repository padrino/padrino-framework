# This allows extlib to act like ActiveSupport for the dependencies required by Padrino

# cattr_accessor
unless Class.method_defined?(:cattr_accessor)
  require 'extlib/class'
end

## Ordered Hash
unless defined?(SupportLite::OrderedHash)
  require 'extlib/dictionary'
  module SupportLite
    OrderedHash = ::Dictionary
  end
end

### Symbolize Keys
unless Hash.method_defined?(:symbolize_keys)
  require 'extlib/hash'
  require 'extlib/mash'
  class Hash
    def symbolize_keys
      Mash.new(self).symbolize_keys
    end
  end
end

## Inflections
unless String.method_defined?(:constantize)
  require 'extlib/inflection'
  class String
    def classify; Extlib::Inflection.classify(self);     end
    def underscore; Extlib::Inflection.underscore(self);  end
    def constantize; Extlib::Inflection.constantize(self); end
  end
end

## Extract Options
unless Array.method_defined?(:extract_options!)
  class Array
    def extract_options!
      last.is_a?(::Hash) ? pop : {}
    end
  end
end

## Blank?
unless Array.method_defined?(:blank?)
  require 'extlib/blank'
end

## Present?
unless Array.method_defined?(:present?)
  class Object
    def present?
      !blank?
    end
  end
end

## Reverse Merge
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

## Alias Method Chain
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
