require 'padrino-core'
require 'padrino-helpers'

FileSet.glob_require('padrino-admin/*.rb', __FILE__)
FileSet.glob_require('padrino-admin/{helpers,utils}/*.rb', __FILE__)

module Padrino
  ##
  # Padrino::Admin is beautiful Ajax Admin, with these features:
  #
  # Orm Agnostic:: Adapters for activerecord, sequel and mongoid
  # Authentication:: Support for Account authentication, Account Permission management
  # Scaffold:: You can simply create a new "admin interface" simply providing a Model
  # Ajax Uploads:: You can upload file, manage them and attach them to any model in a quick and simple way (coming soon)
  #
  module Admin
    class << self
      def registered(app)
        # Load Padrino::Admin locales
        I18n.load_path += Dir["#{__dir__}/padrino-admin/locale/**/*.yml"]
      end
      alias included registered

      ##
      # Whether +error+, raised looking up the constant +name+, says that constant (or one of its
      # namespaces) is not defined, rather than coming from the code that defining it ran.
      #
      def missing_constant?(error, name)
        error.is_a?(NameError) && name.to_s.split('::').include?(error.name.to_s)
      end
    end
  end
end

##
# Now we need to add admin generators to padrino-gen
#
begin
  require 'padrino-gen'
  Padrino::Generators.load_paths << Dir["#{__dir__}/padrino-admin/generators/{actions,keep_files,orm,admin_app,admin_page}.rb"]
rescue LoadError
  # do nothing if padrino-gen is not available
end
