require 'padrino-core'
require 'padrino-gen'
require 'padrino-helpers'

Dir[File.dirname(__FILE__) + '/padrino-admin/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/padrino-admin/{helpers,orm,middleware,utils}/*.rb'].each {|file| require file }

module Padrino
  ##
  # Padrino::Admin is beautiful Ajax Admin, with these fatures:
  # 
  # Orm Agnostic:: Adapters for datamapper, activerecord, mongomapper, couchdb (now only: datamapper and activerecord)
  # Authentication:: Support for Account authentication, Account Permission managment
  # Scaffold:: You can simply create a new "admin interface" simply providing a Model
  # Ajax Uploads:: You can upload file, manage them and attach them to any model in a quick and simple way (coming soon)
  # 
  module Admin; end
end

##
# We need to apply Padrino::Admin::Utils::Extensions
# 
String.send(:include, Padrino::Admin::Utils::Crypt)
String.send(:include, Padrino::Admin::Utils::Literal)

##
# We need to add to Padrino::Application a +access_control+ class
# 
Padrino::Application.send(:cattr_accessor, :access_control)
Padrino::Application.send(:access_control=, Class.new(Padrino::Admin::AccessControl::Base))

##
# If CarrierWave is defined we set the root directory
# 
CarrierWave.root = Padrino.root("public") if defined?(CarrierWave)

##
# Extend Abastract Form builder
# 
Padrino::Helpers::FormBuilder::AbstractFormBuilder.send(:include, Padrino::Admin::Helpers::ViewHelpers::AbstractFormBuilder)

##
# Load our Padrino::Admin locales
# 
I18n.load_path += Dir["#{File.dirname(__FILE__)}/padrino-admin/locale/**/*.yml"]

##
# Load our databases extensions
# 
Padrino::Admin::Orm.register!

##
# Now we need to add admin generators to padrino-gen
# 
Padrino::Generators.load_paths << Dir[File.dirname(__FILE__) + '/padrino-admin/generators/{actions,admin_app,admin_page,admin_uploader}.rb']