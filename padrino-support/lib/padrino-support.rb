##
# This file loads certain extensions required by Padrino.
#
require 'padrino-support/colorizer'
require 'padrino-support/core_ext/string/colorize'
require 'padrino-support/file_set'
require 'padrino-support/utils'

if ENV['AS_VERSION']
  # require ActiveSupport features for tests or legacy projects
  require 'active_support/core_ext/string/output_safety'      # SafeBuffer and html_safe
  require 'active_support/core_ext/object/blank'              # present?
  require 'active_support/core_ext/hash/keys'                 # symbolize_keys
  require 'active_support/core_ext/hash/indifferent_access'   # params[:foo]
  require 'active_support/core_ext/hash/reverse_merge'        # reverse_merge
  require 'active_support/core_ext/module/aliasing'           # alias_method_chain
  require 'active_support/core_ext/array/extract_options'     # Array#extract_options!
  require 'active_support/core_ext/hash/slice'                # slice
  require 'active_support/core_ext/object/deep_dup'
  Padrino::Utils.warn_deprecated('Loading ActiveSupport extensions through AS_VERSION', 'Require the ones your app uses before Padrino instead')
end

# padrino-helpers requires this again once it has loaded I18n.
require 'padrino-support/locale' if defined?(I18n)

##
# Deprecated: Module#_orig_klass_name returns the name Ruby gave a module, even when the module
# overrides +name+. It is removed in Padrino 1.0.
#
class Module
  original_name = instance_method(:name)

  define_method(:_orig_klass_name) do
    unless Padrino.instance_variable_defined?(:@_orig_klass_name_warned)
      Padrino.instance_variable_set(:@_orig_klass_name_warned, true)
      location = caller_locations(1, 1).first
      Warning.warn 'WARNING! Module#_orig_klass_name is deprecated and will be removed in Padrino 1.0. ' \
                   'Use Module.instance_method(:name).bind(mod).call (or just name) instead' \
                   "#{" (called at #{location.path}:#{location.lineno})" if location}.\n"
    end
    original_name.bind_call(self)
  end
end
