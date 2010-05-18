require 'padrino-core'
require 'padrino-gen'
require 'padrino-helpers'

Dir[File.dirname(__FILE__) + '/padrino-admin/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/padrino-admin/{helpers,utils}/*.rb'].each { |file| require file }

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

##
# Load our Padrino::Admin locales
#
I18n.load_path += Dir["#{File.dirname(__FILE__)}/padrino-admin/locale/**/*.yml"]

##
# Now we need to add admin generators to padrino-gen
#
Padrino::Generators.load_paths << Dir[File.dirname(__FILE__) + '/padrino-admin/generators/{actions,orm,admin_app,admin_page}.rb']