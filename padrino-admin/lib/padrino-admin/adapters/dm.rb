module Padrino
  module Admin
    module Adapters
      module Dm

        # Here basic functions for interact with DataMapper
        module Base

          def self.included(base)
            base.send :include, Padrino::Admin::Adapters::Base
            base.send :include, InstanceMethods
            base.extend ClassMethods
          end
          
          module InstanceMethods
            # This method allow us to don't see deprecations
            def new_record?; new?; end

            # Returns a String, which Padrino uses for constructing an URL to this object. 
            # The default implementation returns this record‘s id as a String, or nil if this record‘s unsaved.
            def to_param
              # We can't use alias_method here, because method 'id' optimizes itself on the fly.
              (id = self.id) ? id.to_s : nil # Be sure to stringify the id for routes
            end

            # Update attributes is deprecated but for compatibility with AR we support them.
            def update_attributes(attributes = {})
              update(attributes)
            end
          end

          module ClassMethods
            attr_accessor :_table_name

            def self_and_descendants #:nodoc:
              klass = self
              classes = [klass]
              while klass != klass.base_class  
                classes << klass = klass.superclass
              end
              classes
            rescue
              # OPTIMIZE this rescue is to fix this test: ./test/cases/reflection_test.rb:56:in `test_human_name_for_column'
              # Appearantly the method base_class causes some trouble.
              # It now works for sure.
              [self]
            end

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

            # Return the name of the sql table
            def table_name
              self.name.downcase.pluralize # storage_names[:default] this some times give an error
            end

            # Perform a basic fulltext search/ordering for the given columns
            # 
            # +params+ is an hash like that:
            #   { :sort => "name", :dir => "ASC", :fields=>"name,surname,company", :query => 'daddye' }
            # 
            # In this example we search in columns name, surname, company the string daddye and then we order by
            # column +name+
            def ext_search(params)
              # We need a basic query
              query = {}

              if params[:query].present? && params[:fields].present?
                # Here we build some like: ["name LIKE ?", "surname LIKE ?"]
                fields  = params[:fields].split(",").collect { |f| "#{f.strip.downcase} LIKE ?" }
                # Here we build some like: ["name LIKE ? OR surname LIKE ?", "%foo%", "%foo%"]
                query[:conditions] = [fields.join(" OR ")].concat(1.upto(fields.length).collect { "%#{params[:query]}%" })
              end

              # Now we can perform a search
              all(query)
            end

            def ext_paginate(params)
              # We need a basic query
              query = {}

              # First we need to sort our record
              if params[:sort].present? && params[:dir].to_s =~ /^(asc|desc)$/i
                query[:order] = [params[:sort].to_s.gsub(/#{table_name}\./i,'').to_sym.send(params[:dir].to_s.downcase)]
              end

              # Now time to limit/offset it
              query[:limit]  = params[:limit].to_i  if params[:limit].to_i > 0
              query[:offset] = params[:offset].to_i if params[:offset].to_i > 0

              # Now we can perform ording/limiting
              all(query)
            end
          end
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