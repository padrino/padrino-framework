=begin

This file determines if extlib or activesupport are already loaded, and then ensures
the required objects and methods exist for Padrino to use.

Required for Padrino to run:

  * Class#cattr_accessor
  * Module#alias_method_chain
  * String#inflectors (classify, underscore, camelize, etc)
  * Array#extract_options!
  * Object#blank?
  * Object#present?
  * Hash#slice, Hash#slice!
  * Hash#to_params
  * Hash#symbolize_keys, Hash.symbolize_keys!
  * Hash#reverse_merge, Hash#reverse_merge!
  * SupportLite::OrderedHash

=end
require 'i18n'
# Load our locales
I18n.load_path += Dir["#{File.dirname(__FILE__)}/locale/*.yml"]

module Padrino
  # Return the current support used.
  # Can be one of: :extlib, :active_support
  def self.support
    @_padrino_support
  end
end

if defined?(Extlib) # load if already using extlib
  Padrino.instance_variable_set(:@_padrino_support, :extlib)
  require File.dirname(__FILE__) + '/support_lite/extlib_support'
else # load active support by default
  Padrino.instance_variable_set(:@_padrino_support, :active_support)
  require File.dirname(__FILE__) + '/support_lite/as_support'
end