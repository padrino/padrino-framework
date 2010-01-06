module Padrino
  module Admin
    module Adapters
      module Ar

        # Here basic functions for interact with ActiveRecord
        module Base
          def self.included(base)
            base.send :include, Padrino::Admin::Adapters::Base
            base.send :include, InstanceMethods
            base.extend ClassMethods
            base.class_eval do
              named_scope :ext_search, lambda { |params|
                conditions = nil

                if !params[:query].blank? && !params[:fields].blank?
                  filters = params[:fields].split(",").collect { |f| "#{f} LIKE ?" }.compact
                  conditions = [filters.join(" OR ")].concat((1..filters.size).collect { "%#{params[:query]}%" })
                end

                { :conditions => conditions }
              }
              named_scope :ext_paginate, lambda { |params|
                params.symbolize_keys!
                order = params[:sort].blank? && params[:dir].blank? ? nil : "#{params[:sort]} #{params[:dir]}"
                { :order => order, :limit => params[:limit], :offset => params[:start] }
              }
            end
          end
          
          module InstanceMethods
          end
          
          module ClassMethods
            # Transforms attribute key names into a more humane format, such as "First name" instead of "first_name". Example:
            #   Person.human_attribute_name("first_name") # => "First name"
            # This used to be depricated in favor of humanize, but is now preferred, because it automatically uses the I18n
            # module now.
            # Specify +options+ with additional translating options.
            def human_attribute_name(attribute_key_name, options = {})
              defaults = self_and_descendants.map do |klass|
                :"#{klass.name.underscore}.#{attribute_key_name}"
              end
              defaults << options[:default] if options[:default]
              defaults.flatten!
              defaults << attribute_key_name.to_s.humanize
              options[:count] ||= 1
              I18n.translate(defaults.shift, options.merge(:default => defaults, :scope => [:model, :attributes]))
            end
          end
        end

        # Here extension for account for ActiveRecord
        module Account
          # Extend our class when included
          def self.included(base)
            base.send :include, Padrino::Admin::Adapters::AccountUtils
            base.send :attr_accessor, :password
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