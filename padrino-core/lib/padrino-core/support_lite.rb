##
# This file loads certain extensions required by Padrino from ActiveSupport.
#
require 'active_support/core_ext/string/conversions'        unless String.method_defined?(:to_date)
require 'active_support/core_ext/kernel'                    unless Kernel.method_defined?(:silence_warnings)
require 'active_support/core_ext/module'                    unless Module.method_defined?(:alias_method_chain)
require 'active_support/core_ext/class/attribute_accessors' unless Class.method_defined?(:cattr_reader)
require 'active_support/core_ext/hash/keys'                 unless Hash.method_defined?(:symbolize_keys!)
require 'active_support/core_ext/hash/deep_merge'           unless Hash.method_defined?(:deep_merge)
require 'active_support/core_ext/hash/reverse_merge'        unless Hash.method_defined?(:reverse_merge)
require 'active_support/core_ext/hash/slice'                unless Hash.method_defined?(:slice)
require 'active_support/core_ext/object/blank'              unless Object.method_defined?(:present?)
require 'active_support/core_ext/array'                     unless Array.method_defined?(:from)
require 'active_support/ordered_hash'                       unless defined?(ActiveSupport::OrderedHash)
require 'active_support/inflector'                          unless String.method_defined?(:humanize)
require 'active_support/core_ext/float/rounding'            unless Float.method_defined?(:round)
require 'active_support/option_merger'                      unless defined?(ActiveSupport::OptionMerger)
require 'active_support/core_ext/object/with_options'       unless Object.method_defined?(:with_options)

##
# Used to know if this file has already been required
#
module SupportLite; end

module ObjectSpace
  class << self
    # Returns all the classes in the object space.
    def classes
      ObjectSpace.each_object(Module).map.select do |klass|
        Class.class_eval { klass } rescue false
      end
    end
  end
end

##
# FileSet helper method for iterating and interacting with files inside a directory
#
class FileSet
  # Iterates over every file in the glob pattern and yields to a block
  # Returns the list of files matching the glob pattern
  # FileSet.glob('padrino-core/application/*.rb', __FILE__) { |file| load file }
  def self.glob(glob_pattern, file_path=nil, &block)
    glob_pattern = File.join(File.dirname(file_path), glob_pattern) if file_path
    file_list = Dir.glob(glob_pattern).sort
    file_list.each { |file| block.call(file) }
    file_list
  end

  # Requires each file matched in the glob pattern into the application
  # FileSet.glob_require('padrino-core/application/*.rb', __FILE__)
  def self.glob_require(glob_pattern, file_path=nil)
    self.glob(glob_pattern, file_path) { |f| require f }
  end
end

##
# YAML Engine Parsing Fix
# https://github.com/padrino/padrino-framework/issues/424
#
require 'yaml' unless defined?(YAML)
YAML::ENGINE.yamler = "syck" if defined?(YAML::ENGINE)

##
# Loads our locale configuration files
#
I18n.load_path += Dir["#{File.dirname(__FILE__)}/locale/*.yml"] if defined?(I18n)
