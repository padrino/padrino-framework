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
      # namespaces) is not defined, rather than coming from the code that defining it ran. The
      # error must name a segment of +name+ and have been raised on that segment's parent, so a
      # model whose body references another constant with the same short name isn't "missing".
      #
      def missing_constant?(error, name)
        return false unless error.instance_of?(NameError)

        segments = name.to_s.sub(/\A::/, '').split('::')
        return false unless error.receiver.is_a?(::Module)

        segments.each_index.any? do |index|
          parent = index.zero? ? 'Object' : segments.first(index).join('::')
          segments[index] == error.name.to_s && error.receiver.name == parent
        end
      rescue ArgumentError
        false
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
