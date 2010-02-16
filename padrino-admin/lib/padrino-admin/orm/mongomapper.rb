module Padrino
  module Admin
    module Orm
      module MongoMapper
        ##
        # Here basic functions for interact with MongoMapper
        # 
        module Base

          def self.included(base) #:nodoc:
            base.send :include, Padrino::Admin::Orm::Abstract::Base
            base.send :include, InstanceMethods
            base.extend ClassMethods
          end

          module InstanceMethods
          end # InstanceMethods

          module ClassMethods
            ##
            # Return :activerecord
            # 
            def orm
              :mongomapper
            end
          end # ClassMethods
        end # Base

        ##
        # Here extension for Account for MongoMapper
        # 
        # Basically we need only to perform:
        # 
        # * Validations (email, password, role)
        # * Generate crypted_password on save
        # 
        module Account

          def self.included(base) #:nodoc:
            super(base)
            base.send :include, Padrino::Admin::Orm::Abstract::Account
            base.send :attr_accessor, :password, :password_confirmation
            # Properties
            base.key :email,            String
            base.key :crypted_password, String
            base.key :salt,             String
            base.key :role,             String
            # Validations
            base.validates_presence_of     :email, :role
            base.validates_presence_of     :password,                   :if => :password_required
            base.validates_presence_of     :password_confirmation,      :if => :password_required
            base.validates_length_of       :password, :within => 4..40, :if => :password_required
            base.validates_confirmation_of :password,                   :if => :password_required
            base.validates_length_of       :email,    :within => 3..100
            base.validates_uniqueness_of   :email,    :case_sensitive => false
            base.validates_format_of       :email,    :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
            base.validates_format_of       :role,     :with => /[A-Za-z]/
            # Callbacks
            base.before_save :generate_password
          end
        end # Account
      end # MongoMapper
    end # Orm
  end # Admin
end # Padrino