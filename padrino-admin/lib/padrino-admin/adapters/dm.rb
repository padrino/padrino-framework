module Padrino
  module Admin
    module Adapters
      module Dm

        # Here basic functions for interact with DataMapper
        module Base
          include Padrino::Admin::Adapters::Base

          def new_record?; new?; end
        end

        # Here extension for account for DataMapper
        module Account
          # Extend our class when included
          def self.included(base)
            super
            base.send :include, Padrino::Admin::Adapters::AccountUtils
            base.send :include, DataMapper::Validate
            base.send :attr_accessor, :password, :password_confirmation
            # Properties
            base.property :email,            String
            base.property :crypted_password, String
            base.property :salt,             String
            base.property :role,             String
            # Validations
            base.validates_present      :email, :role
            base.validates_present      :password,                          :if => :password_required
            base.validates_present      :password_confirmation,             :if => :password_required
            base.validates_length       :password, :min => 4, :max => 40,   :if => :password_required
            base.validates_is_confirmed :password,                          :if => :password_required
            base.validates_length       :email,    :min => 3, :max => 100
            base.validates_is_unique    :email,    :case_sensitive => false
            base.validates_format       :email,    :with => :email_address
            base.validates_format       :role,     :with => /[A-Za-z]/
            # Callbacks
            base.before :save, :generate_password
          end
        end
      end
    end
  end
end