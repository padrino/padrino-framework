# Loaded by the autoload in output_safety.rb the first time the top-level SafeBuffer is referenced.
require 'rbconfig'

# A reloader that tracks this file as a feature of an app file may load it again: warn only once.
return if Padrino.instance_variable_defined?(:@_top_level_safe_buffer_warned)

Padrino.instance_variable_set(:@_top_level_safe_buffer_warned, true)

# The frames before the reference are require and its wrappers (RubyGems, Bundler, Bootsnap,
# ActiveSupport's load_dependency...). ceiling: a wrapper named otherwise is reported as the
# reference; the upgrade path is a list of wrapper paths instead of labels.
ruby_lib = RbConfig::CONFIG['rubylibdir']
reference = caller_locations.find do |location|
  label = location.base_label.to_s
  !label.include?('require') && label != 'load_dependency' && !location.path.start_with?('<internal:', ruby_lib)
end
# Warning.warn prints even while $VERBOSE is nil, as it is while the reloader loads app files:
# this file runs once, so a warning dropped there would never be seen.
Warning.warn 'WARNING! The top-level SafeBuffer constant is deprecated and will be removed in Padrino 1.0. ' \
             "Use Padrino::SafeBuffer instead#{" (first referenced at #{reference.path}:#{reference.lineno})" if reference}.\n"

SafeBuffer = Padrino::SafeBuffer
