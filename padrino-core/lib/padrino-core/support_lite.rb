=begin

This file determines if Extlib or Activesupport are already loaded, and then ensures
required methods exist for Padrino to use.

required methods:

  * Class#cattr_accessor
  * Module#alias_method_chain
  * String#inflectors (classify, underscore, camelize, etc)
  * Hash#extract_options!
  * Object#blank?
  * Object#present?
  * Hash#symbolize_keys
  * Hash#reverse_merge, Hash#reverse_merge!
  * SupportLite::OrderedHash

=end


if defined?(ActiveSupport)
  require File.dirname(__FILE__) + '/support_lite/as_support'
elsif defined?(Extlib)
  require File.dirname(__FILE__) + '/support_lite/extlib_support'
else # just use active support by default
  require File.dirname(__FILE__) + '/support_lite/as_support'
end
