# This requires necessary pieces of ActiveSupport for the dependencies required by Padrino

require 'active_support/inflector' unless String.method_defined?(:constantize)
require 'active_support/core_ext/blank' unless Object.method_defined?(:blank?)
require 'active_support/core_ext/class/attribute_accessors' unless Class.method_defined?(:cattr_accessor)
require 'active_support/core_ext/hash' unless Hash.method_defined?(:reverse_merge)
require 'active_support/core_ext/array' unless Array.method_defined?(:extract_options!)
require 'active_support/core_ext/module' unless Module.method_defined?(:alias_method_chain)
require 'active_support/ordered_hash' unless defined?(ActiveSupport::OrderedHash)

module SupportLite
  OrderedHash = ::ActiveSupport::OrderedHash
end
