module Padrino
  module Admin
    module Orm
      module ActiveRecord
        ##
        # Here basic functions for interact with ActiveRecord
        # 
        module Base

          def self.included(base) #:nodoc:
            base.send :include, Padrino::Admin::Orm::Abstract::Base
            base.send :include, InstanceMethods
            base.extend ClassMethods
          end

          module InstanceMethods
            ##
            # Method for get only fields with errors
            # 
            def errors_keys
              errors.map { |k,v| k.to_sym }.uniq
            end
          end # InstanceMethods

          module ClassMethods
            ##
            # Transforms attribute key names into a more humane and localizable format, such as "First name" instead of "first_name". 
            # 
            # ==== Examples
            #   # Do: I18n.translate("models.person.attributes.first_name")
            #   Person.human_local_attribute_name("first_name") # => "First name"
            # 
            # Specify +options+ with additional translating options.
            # 
            def human_local_attribute_name(field, options = {})
              options.reverse_merge!(:count => 1, :default => field.to_s.humanize, :scope => :models)
              I18n.translate("#{self.name.underscore}.attributes.#{field}", options)
            end

            ##
            # Transform table name into a more humane and localizable format, such as "Blog Posts" instead of "BlogPost". 
            # 
            # ==== Examples
            #   # Do: I18n.translate("models.person.name")
            #   Person.human_local_name # => "Persona"
            # 
            # Specify +options+ with additional translating options.
            # 
            def human_local_name(options = {})
              options.reverse_merge!(:count => 1, :default => self.name.humanize, :scope => :models)
              I18n.translate("#{self.name.underscore}.name", options)
            end

            ##
            # Alias method for get columns names
            # 
            def properties
              columns
            end

            ##
            # Return :activerecord
            # 
            def orm
              :activerecord
            end

            ##
            # Method for perorm a full text search / sorting in ExtJS grids.
            # 
            # For build a query you can provide for +params+:
            # 
            # query:: word do search will be converted to "%word%"
            # fields:: where you want search
            # sort:: field to sort
            # dir:: one of ASC/DESC
            # limit:: limit your results 
            # start:: offset of your resluts
            # 
            # For +query+ we mean standard adapter options such as +include+, +joins+ ...
            # 
            # So a +ext_search+ can be:
            # 
            #   Account.ext_search({:query => "foo", fileds="name,surname,categories.name", :sort => "name", 
            #                       :dir => "asc", :limit => 50, :offset => 10 }, { :joins => :categories })
            # 
            def ext_search(params, query={})

              # We build a base struct for have some good results
              result = ExtSearch.new(0, [])

              # Search conditions
              if params[:query].present? && params[:fields].present?
                filters = params[:fields].split(",").collect { |f| "#{f} LIKE ?" }.compact
                query[:conditions] = [filters.join(" OR ")].concat((1..filters.size).collect { "%#{params[:query]}%" })
              end

              result.count = count(query)

              # Order conditions
              query[:order] = params[:sort].present? && params[:dir].to_s =~ /^(asc|desc)$/i ? "#{params[:sort]} #{params[:dir]}" : nil

              # Now time to limit/offset it
              query[:limit]  = params[:limit].to_i  if params[:limit].to_i > 0
              query[:offset] = params[:start].to_i  if params[:start].to_i > 0

              result.records = all(query)
              result
            end

          end # ClassMethods
        end # Base

        ##
        # Here extension for Account for ActiveRecord
        # 
        # Basically we need only to perform:
        # 
        # * Validations (email, password, role)
        # * Generate crypted_password on save
        # 
        module Account

          def self.included(base) #:nodoc:
            base.send :include, Padrino::Admin::Orm::Abstract::Account
            base.send :attr_accessor, :password
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
      end # ActiveRecord
    end # Orm
  end # Admin
end # Padrino