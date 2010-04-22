##
# Manages Padrino version from the VERSION file managed by Jeweler
# We put this in a separate file so you can get padrino version
# without include full padrino core.
#
module Padrino
  VERSION = '0.9.10' unless defined?(Padrino::VERSION)
  ##
  # Return the current Padrino version
  #
  def self.version
    VERSION
  end
end # Padrino
