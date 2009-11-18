# Manages Padrino version from the VERSION file managed by Jeweler

module Padrino
  def self.version
    @version ||= File.read(File.dirname(__FILE__) + '/../../VERSION').chomp
  end
end