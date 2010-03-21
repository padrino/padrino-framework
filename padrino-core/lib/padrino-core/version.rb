##
# Manages Padrino version from the VERSION file managed by Jeweler
# We put this in a separate file so you can get padrino version
# without include full padrino core.
#
module Padrino
  ##
  # Return the current Padrino version
  #
  def self.version
    @version ||= File.read(File.dirname(__FILE__) + '/../../VERSION').chomp
  end
end # Padrino