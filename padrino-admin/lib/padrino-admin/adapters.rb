require 'openssl'
require 'digest/sha1'

module Padrino
  module Admin

    class AdapterError < StandardError; end

    module Adapters
      # This method it's used for register for the specified ORM the extensions.
      def self.register(adapter, klass=nil)
        klass ||= Account
        case adapter
          when :active_record
            ActiveRecord::Base.send(:include, Padrino::Admin::Adapters::Ar::Base)
            klass.send(:include, Padrino::Admin::Adapters::Ar::Account)
          when :data_mapper
            DataMapper::Model.descendants.each { |d| d.send(:include, Padrino::Admin::Adapters::Dm::Base) }
            klass.send(:include, Padrino::Admin::Adapters::Dm::Account)
          when :mongo_mapper
            MongoMapper::Document.append_inclusions(Padrino::Admin::Adapters::Mm::Base)
            klass.send(:include, Padrino::Admin::Adapters::Mm::Account)
          else
            raise Padrino::Admin::AdapterError, "The adapter #{adapter.inspect} is not supported, available adapters are: " + 
                                                ":active_record, :data_mapper, :mongo_mapper"
        end
      end

      # Here standard extension
      module Base
        # TODO
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
            account = first(:conditions => { :email => email })
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