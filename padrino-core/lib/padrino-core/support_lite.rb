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
  * Hash#symbolize_keys
  * Hash#reverse_merge, Hash#reverse_merge!
  * SupportLite::OrderedHash

=end
@_padrino_support_loaded ||= false

unless @_padrino_support_loaded
  if defined?(Extlib) # load if already using extlib
    require File.dirname(__FILE__) + '/support_lite/extlib_support'
    puts "=> Loaded Extlib support... "
  else # load active support by default
    require File.dirname(__FILE__) + '/support_lite/as_support'
    puts "=> Loaded ActiveSupport... "
  end
end

@_padrino_support_loaded = true