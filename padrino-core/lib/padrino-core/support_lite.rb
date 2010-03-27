##
# This file loads certain extensions required by Padrino from ActiveSupport.
#
# Why use ActiveSupport and not our own library or extlib?
#
# 1) Writing custom method extensions needed (i.e string inflections) is not a good use of time.
# 2) Loading custom method extensions or separate gem would conflict when AR or MM has been loaded.
# 3) Datamapper is planning to move to ActiveSupport and away from extlib.
#
# Extensions required for Padrino:
#
#   * Class#cattr_accessor
#   * Module#alias_method_chain
#   * String#inflectors (classify, underscore, camelize, pluralize, etc)
#   * Array#extract_options!
#   * Object#blank?
#   * Object#present?
#   * Hash#slice, Hash#slice!
#   * Hash#to_params
#   * Hash#symbolize_keys, Hash.symbolize_keys!
#   * Hash#reverse_merge, Hash#reverse_merge!
#   * Symbol#to_proc
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
require 'active_support/core_ext/symbol'
require 'active_support/ordered_hash'

##
# Define our own OrderedHash based on AS::OrderedHash
#
unless defined?(SupportLite::OrderedHash)
  module SupportLite
    OrderedHash = ::ActiveSupport::OrderedHash
  end
end

##
# Alias allowing for use of either method to get query parameters
#
unless Hash.method_defined?(:to_params)
  class Hash
    alias :to_params :to_query
  end
end

##
# Loads our locales configuration files
#
I18n.load_path += Dir["#{File.dirname(__FILE__)}/locale/*.yml"]