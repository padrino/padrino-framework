##
# This file loads certain extensions required by Padrino from ActiveSupport.
#
# Why use ActiveSupport and not our own library or extlib?
#
# 1) Rewriting custom method extensions needed (i.e string inflectors) is not a good use of time.
# 2) Loading custom method extensions or separate gems would conflict with AS when AR or MM has been loaded.
# 3) Datamapper 1.0 supports ActiveSupport 3.0 and no longer requires extlib.
#

require 'active_support/core_ext/string/conversions' unless String.method_defined?(:to_date)
require 'active_support/core_ext/kernel'             unless Kernel.method_defined?(:silence_warnings)
require 'active_support/core_ext/module'             unless Module.method_defined?(:alias_method_chain)
require 'active_support/core_ext/class/attribute_accessors' unless Class.method_defined?(:cattr_reader)
require 'active_support/core_ext/hash/keys'          unless Hash.method_defined?(:symbolize_keys!)
require 'active_support/core_ext/hash/deep_merge'    unless Hash.method_defined?(:deep_merge)
require 'active_support/core_ext/hash/reverse_merge' unless Hash.method_defined?(:reverse_merge)
require 'active_support/core_ext/hash/slice'         unless Hash.method_defined?(:slice)
require 'active_support/core_ext/object/blank'       unless Object.method_defined?(:present?)
require 'active_support/core_ext/array'              unless Array.method_defined?(:from)
require 'active_support/ordered_hash'                unless defined?(ActiveSupport::OrderedHash)
require 'active_support/inflector'                   unless String.method_defined?(:humanize)
require 'active_support/core_ext/float/rounding'     unless Float.method_defined?(:round)
require 'active_support/option_merger'               unless defined?(ActiveSupport::OptionMerger)

begin
  require 'active_support/core_ext/symbol'
rescue LoadError
  # AS 3.0 has been removed it because is now available in Ruby > 1.8.7 but we want keep Ruby 1.8.6 support.
  class Symbol
    # Turns the symbol into a simple proc, which is especially useful for enumerations like: people.map(&:name)
    def to_proc
      Proc.new { |*args| args.shift.__send__(self, *args) }
    end
  end unless :to_proc.respond_to?(:to_proc)
end

# On ActiveSupport < 3.0.0 this is called misc
begin
  require 'active_support/core_ext/object/with_options'
rescue LoadError
  require 'active_support/core_ext/object/misc'
end unless Object.method_defined?(:with_options)

if defined?(ActiveSupport::CoreExtensions::Hash) && !Hash.method_defined?(:slice)
  # This mean that we are using AS 2.3.x
  class Hash
    include ActiveSupport::CoreExtensions::Hash::Keys
    include ActiveSupport::CoreExtensions::Hash::DeepMerge
    include ActiveSupport::CoreExtensions::Hash::ReverseMerge
    include ActiveSupport::CoreExtensions::Hash::Slice
    
    def ordered_collect(&block)
      keys = self.stringify_keys.keys.sort
      keys.collect { |key| block.call(key, self[key.to_sym]) }
    end
  end
end

##
# Used to know if this file was required
#
module SupportLite; end unless defined?(SupportLite)

module ObjectSpace
  class << self
    # Returns all the classes in the object space.
    def classes
      klasses = []
      ObjectSpace.each_object(Class) {|o| klasses << o}
      klasses
    end
  end
end unless ObjectSpace.respond_to?(:classes)

class Object
  def full_const_get(name)
    list = name.split("::")
    list.shift if list.first.blank?
    obj = self
    list.each do |x|
      # This is required because const_get tries to look for constants in the
      # ancestor chain, but we only want constants that are HERE
      obj = obj.const_defined?(x) ? obj.const_get(x) : obj.const_missing(x)
    end
    obj
  end
end unless Object.method_defined?(:full_const_get)

# FileSet helper method for iterating and interacting with files inside a directory
class FileSet
  # Iterates over every file in the glob pattern and yields to a block
  # Returns the list of files matching the glob pattern
  # FileSet.glob_require('padrino-core/application/*.rb', __FILE__) { |file| load file }
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
end unless defined?(FileSet)

##
# Loads our locales configuration files
#
I18n.load_path += Dir["#{File.dirname(__FILE__)}/locale/*.yml"] if defined?(I18n)
