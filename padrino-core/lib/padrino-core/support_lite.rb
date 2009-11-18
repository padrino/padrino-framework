# This is for adding specific methods that are required by padrino if activesupport isn't required
unless String.method_defined?(:titleize) && Hash.method_defined?(:slice)
  require 'active_support/inflector'
  require 'active_support/core_ext/blank'
  require 'active_support/core_ext/class/attribute_accessors'
  require 'active_support/core_ext/hash'
  require 'active_support/core_ext/array'
  require 'active_support/core_ext/module'
end