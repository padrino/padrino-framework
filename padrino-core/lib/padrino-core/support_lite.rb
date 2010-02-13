##
# This file load some usefull extensions from Active Support.
# 
# Why ActiveSupport and not ours or extlib?
# 
# We don't love so much rewite code and we don't use extlib because:
# 
#   1) ActiveRecord need ActiveSupport
#   2) MongoMapper need ActiveSuport
#   3) DataMapper it's planning to migrate to ActiveSupport (see: http://wiki.github.com/datamapper/dm-core/roadmap)
# 
# Required for Padrino to run:
# 
#   * Class#cattr_accessor
#   * Module#alias_method_chain
#   * String#inflectors (classify, underscore, camelize, etc)
#   * Array#extract_options!
#   * Object#blank?
#   * Object#present?
#   * Hash#slice, Hash#slice!
#   * Hash#to_params
#   * Hash#symbolize_keys, Hash.symbolize_keys!
#   * Hash#reverse_merge, Hash#reverse_merge!
#   * SupportLite::OrderedHash
# 

require 'i18n'
require 'active_support/core_ext/kernel'
require 'active_support/core_ext/module'
require 'active_support/deprecation'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/hash'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/array'
require 'active_support/core_ext/module'
require 'active_support/ordered_hash'

##
# Define our Ordered Hash
# 
unless defined?(SupportLite::OrderedHash)
  module SupportLite
    OrderedHash = ::ActiveSupport::OrderedHash
  end
end

##
# We new alwasy :to_params in a Hash
# 
unless Hash.method_defined?(:to_params)
  class Hash 
    alias :to_params :to_query
  end
end

##
# Load our locales
# 
I18n.load_path += Dir["#{File.dirname(__FILE__)}/locale/*.yml"]