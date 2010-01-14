require 'openssl'
require 'digest/sha1'

module Padrino
  module Admin

    class AdapterError < StandardError; end

    class ExtSearch < Struct.new(:count, :records); end

    module Adapters
      # This method it's used for register for the specified ORM the extensions.
      def self.register(adapter, klass=nil)
        klass ||= Account
        case adapter
          when :activerecord
            ActiveRecord::Base.send(:include, Padrino::Admin::Adapters::Ar::Base)
            klass.send(:include, Padrino::Admin::Adapters::Ar::Account)
          when :datamapper
            DataMapper::Model.descendants.each { |d| d.send(:include, Padrino::Admin::Adapters::Dm::Base) }
            klass.send(:include, Padrino::Admin::Adapters::Dm::Account)
          # Not yet finished
          when :mongomapper
            MongoMapper::Document.append_inclusions(Padrino::Admin::Adapters::Mm::Base)
            klass.send(:include, Padrino::Admin::Adapters::Mm::Account)
          else
            raise Padrino::Admin::AdapterError, "The adapter #{adapter.inspect} is not supported, available adapters are: " + 
                                                ":activerecord, :datamapper, :mongomapper"
        end
      end

      # Here standard extension
      module Base
        def self.included(base)
          base.send :include, InstanceMethods
          base.extend ClassMethods
        end

        module InstanceMethods
        end

        module ClassMethods
          # This method generate store and column config.
          # for lazinies hands instead supply:
          # 
          #   Model.column_store("./../views/model/store.jml")
          # 
          # you can:
          # 
          #   Model.column_store(options.views, "models/store")
          def column_store(*args)
            path   = File.join(*args)
            path   = Dir[path + ".{jml,jaml}"].first.to_s if path !~ /(\.jml|\.jaml)$/
            config = YAML.load_file(path)
            Padrino::ExtJs::ColumnStore.new(self, config)
          end
        end
      end
      # Here extension for account
      # 
      # An Account must have these column/fields:
      # 
      # role:: String
      # email:: String (used as login)
      # crypted_password:: String
      # salt:: String
      # 
      # We add to Account model some methods:
      # 
      # Account.authenticate(email, password):: check if exist an account for the given email and return it if password match
      # account.password_clean:: return the decrypted password of an Account instance
      # 
      module AccountUtils

        def self.included(base) #:nodoc:
          base.extend ClassMethods
          base.send :include, InstanceMethods
        end

        module ClassMethods
          # This method it's for authentication purpose
          def authenticate(email, password)
            account = first(:conditions => { :email => email }) if email.present?
            account && account.password_clean == password ? account : nil
          end
        end

        module InstanceMethods
          # This method it's used for retrive the original password.
          def password_clean
            crypted_password.decrypt(salt)
          end

        private
          def generate_password
            return if password.blank?
            self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
            self.crypted_password = password.encrypt(self.salt)
          end

          def password_required
            crypted_password.blank? || !password.blank?
          end
        end
      end
    end
  end
end