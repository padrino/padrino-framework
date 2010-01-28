require 'tilt'
require 'thor'
require 'padrino-core'
require 'padrino-gen'
require 'padrino-helpers'

Dir[File.dirname(__FILE__) + '/padrino-admin/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/padrino-admin/{helpers,orm,generators,middleware,utils}/*.rb'].each {|file| require file }

##
# We need to apply Padrino::Admin::Utils::Extensions
# 
String.send(:include, Padrino::Admin::Utils::Crypt)
String.send(:include, Padrino::Admin::Utils::Literal)

##
# We need to add to Padrino::Application a +access_control+ class
# 
Padrino::Application.send(:cattr_accessor, :access_control)
Padrino::Application.send(:access_control=, Class.new(Padrino::AccessControl::Base))

##
# If CarrierWave is defined we set the root directory
# 
CarrierWave.root = Padrino.root if defined?(CarrierWave)

##
# Extend Abastract Form builder
# 
Padrino::Helpers::FormBuilder::AbstractFormBuilder.send(:include, Padrino::Admin::Helpers::AbstractFormBuilder)

##
# Load our Padrino::Admin locales
# 
I18n.load_path += Dir["#{File.dirname(__FILE__)}/padrino-admin/locale/**/*.yml"]

##
# Load our databases extensions
# 
Padrino::Admin::Orm.register!