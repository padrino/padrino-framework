# Loaded by the autoload in output_safety.rb the first time the top-level SafeBuffer is referenced.
require 'rbconfig'

# The frames before the reference are require and its wrappers (RubyGems, Bundler, Bootsnap...).
ruby_lib = RbConfig::CONFIG['rubylibdir']
reference = caller_locations.find do |location|
  location.base_label != 'require' && !location.path.start_with?('<internal:', ruby_lib)
end
# Warning.warn prints even while $VERBOSE is nil, as it is while the reloader loads app files:
# this file runs once, so a warning dropped there would never be seen.
Warning.warn 'WARNING! The top-level SafeBuffer constant is deprecated and will be removed in Padrino 1.0. ' \
             "Use Padrino::SafeBuffer instead#{" (first referenced at #{reference.path}:#{reference.lineno})" if reference}.\n"

SafeBuffer = Padrino::SafeBuffer
