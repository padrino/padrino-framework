require 'padrino-core'
require 'padrino-helpers'

FileSet.glob_require('padrino-admin/*.rb', __FILE__)
FileSet.glob_require('padrino-admin/{helpers,utils}/*.rb', __FILE__)

module Padrino
  ##
  # Padrino::Admin is beautiful Ajax Admin, with these features:
  #
  # Orm Agnostic:: Adapters for datamapper, activerecord, mongomapper, couchdb (now only: datamapper and activerecord), ohm
  # Authentication:: Support for Account authentication, Account Permission management
  # Scaffold:: You can simply create a new "admin interface" simply providing a Model
  # Ajax Uploads:: You can upload file, manage them and attach them to any model in a quick and simple way (coming soon)
  #
  module Admin
    class << self
      def registered(app)
        # Load Padrino::Admin locales
        I18n.load_path += Dir["#{File.dirname(__FILE__)}/padrino-admin/locale/**/*.yml"]
      end
      alias :included :registered
    end
  end
end

##
# Now we need to add admin generators to padrino-gen
#
begin
  require 'padrino-gen'
  Padrino::Generators.load_paths << Dir[File.dirname(__FILE__) + '/padrino-admin/generators/{actions,orm,admin_app,admin_page}.rb']
rescue LoadError
end
