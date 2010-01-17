module Padrino
  module Admin

    module Orm

      class ExtSearch < Struct.new(:count, :records); end

      ##
      # Method used for register the orm extensions.
      # 
      def self.register!
        # Register Orm extension
        ::DataMapper::Model.append_inclusions(Padrino::Admin::Orm::DataMapper::Base)      if defined?(::DataMapper)
        ::ActiveRecord::Base.send(:include, Padrino::Admin::Orm::ActiveRecord::Base)      if defined?(::ActiveRecord)
        ::MongoMapper::Document.append_inclusions(Padrino::Admin::Orm::MongoMapper::Base) if defined?(::MongoMapper)

        # Now extend our Account class if present
        if defined?(Account) && Account.respond_to?(:orm)
          case Account.orm
            when :activerecord then Account.send(:include, Padrino::Admin::Orm::ActiveRecord::Account)
            when :datamapper   then Account.send(:include, Padrino::Admin::Orm::DataMapper::Account)
            when :mongomapper  then Account.send(:include, Padrino::Admin::Orm::MongoMapper::Account)
          end
        end
      end
    end # Orm
  end # Admin
end # Padrino