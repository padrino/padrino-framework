# This requires necessary pieces of ActiveSupport for the dependencies required by Padrino

## ActiveSupport::Deprecation
unless defined?(ActiveSupport::Deprecation)
  require 'active_support/core_ext/kernel' unless Kernel.method_defined?(:silence_warnings)
  require 'active_support/core_ext/module' unless Module.method_defined?(:mattr_accessor)
  require 'active_support/deprecation'
end
## Class#cattr_accessor
require 'active_support/core_ext/class/attribute_accessors' unless Class.method_defined?(:cattr_accessor)
## Hash#symbolize_keys, Hash#reverse_merge, Hash#reverse_merge!, Hash#extract_options!, Hash#slice!
require 'active_support/core_ext/hash' unless Hash.method_defined?(:reverse_merge)
## Hash#to_params
require 'active_support/core_ext/object' unless Object.method_defined?(:to_query)
class Hash; alias :to_params :to_query; end unless Hash.method_defined?(:to_params)
## Object#with_options
require 'active_support/option_merger'
## String#inflectors
require 'active_support/inflector' unless String.method_defined?(:constantize)
## Object#blank?, Object#present?
require 'active_support/core_ext/object' unless Object.method_defined?(:blank?)
require 'active_support/core_ext/blank' unless Object.method_defined?(:blank?)
## Array#extract_options!
require 'active_support/core_ext/array' unless Array.method_defined?(:extract_options!)
## Module#alias_method_chain
require 'active_support/core_ext/module' unless Module.method_defined?(:alias_method_chain)
## SupportLite::OrderedHash
require 'active_support/ordered_hash' unless defined?(ActiveSupport::OrderedHash)
unless defined?(SupportLite::OrderedHash)
  module SupportLite
    OrderedHash = ::ActiveSupport::OrderedHash
  end
end
