module Padrino
  module Admin

    module Orm

      class ExtSearch < Struct.new(:count, :records); end

      ##
      # Method used for register the orm extensions.
      # 
      def self.register!
        ::DataMapper::Model.append_inclusions(Padrino::Admin::Orm::DataMapper::Base)      if defined?(::DataMapper)
        ::ActiveRecord::Base.send(:include, Padrino::Admin::Orm::ActiveRecord::Base)      if defined?(::ActiveRecord)
        ::MongoMapper::Document.append_inclusions(Padrino::Admin::Orm::MongoMapper::Base) if defined?(::MongoMapper)
        # Extend also account model
        self.extend_account!
      end

      ##
      # This method it's used for extend Account Model (if present)
      # 
      def self.extend_account!
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