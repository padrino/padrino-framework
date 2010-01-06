module Padrino
  module Admin
    module Adapters
      module Mm

        # Here basic functions for interact with MongoMapper
        module Base
          def self.included(base)
            base.send :include, Padrino::Admin::Adapters::Base
            base.send :include, InstanceMethods
            base.extend ClassMethods
          end
          
          module InstanceMethods
          end
          
          module ClassMethods
          end
        end

        # Here extension for account for DataMapper
        module Account
          # Extend our class when included
          def self.included(base)
            super
            base.send :include, Padrino::Admin::Adapters::AccountUtils
            base.send :attr_accessor, :password, :password_confirmation
            # Properties
            base.key :email,            String
            base.key :crypted_password, String
            base.key :salt,             String
            base.key :role,             String
            # Validations
            base.validates_presence_of     :email
            base.validates_presence_of     :password,                   :if => :password_required
            base.validates_presence_of     :password_confirmation,      :if => :password_required
            base.validates_length_of       :password, :within => 4..40, :if => :password_required
            base.validates_confirmation_of :password,                   :if => :password_required
            base.validates_length_of       :email,    :within => 3..100
            base.validates_uniqueness_of   :email,    :case_sensitive => false
            base.validates_format_of       :email,    :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
            # Callbacks
            base.before_save :generate_password
          end
        end
      end
    end
  end
end