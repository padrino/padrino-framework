#
# Manages current Padrino version for use in gem generation.
#
# We put this in a separate file so you can get padrino version
# without include full padrino core.
#
module Padrino
  # The version constant for the current version of Padrino.
<<<<<<< HEAD
  VERSION = '0.14.0' unless defined?(Padrino::VERSION)
=======
  VERSION = '0.14.4' unless defined?(Padrino::VERSION)
>>>>>>> d52f29e24866d879cd87cf1dc88a3c615e0c20f5

  #
  # The current Padrino version.
  #
  # @return [String]
  #   The version number.
  #
  def self.version
    VERSION
  end
end # Padrino
