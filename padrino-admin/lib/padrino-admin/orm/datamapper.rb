module Padrino
  module Admin
    module Orm
      module DataMapper
        ##
        # Here basic functions for interact with DataMapper
        # 
        module Base

          def self.included(base) #:nodoc:
            base.send :include, Padrino::Admin::Orm::Abstract::Base
            base.send :include, InstanceMethods
            base.extend ClassMethods
          end
          
          module InstanceMethods
            ##
            # This is an alias method to allow us to don't see deprecations 
            # and keep compatibility with new DataMapper versions
            # 
            def new_record?; new?; end

            ##
            # Returns a String, which Padrino uses for constructing an URL to this object. 
            # The default implementation returns this record‘s id as a String, 
            # or nil if this record‘s unsaved.
            # 
            def to_param
              # We can't use alias_method here, because method 'id' optimizes itself on the fly.
              (id = self.id) ? id.to_s : nil # Be sure to stringify the id for routes
            end

            ##
            # Update attributes is deprecated but for compatibility with other ORM we support them.
            # 
            def update_attributes(attributes = {})
              update(attributes)
            end

            ##
            # Method for get only fields with errors
            # 
            def errors_keys
              errors.keys
            end
          end # InstanceMethods

          module ClassMethods
            ##
            # Transforms attribute key names into a more humane format, such as "First name" instead of "first_name". 
            # 
            # Example:
            #   Person.human_attribute_name("first_name") # => "First name"
            # 
            # Specify +options+ with additional translating options.
            # 
            def human_attribute_name(field, options = {})
              options.reverse_merge!(:count => 1, :default => field.to_s.humanize, :scope => [:model, :attributes])
              I18n.translate("#{self.name.underscore}.#{field}", options)
            end

            ##
            # Return the name of the Table
            # 
            # Because in some unkown circumstances +storage_names[:default]+ give us an wrong value
            # we use the class name for get the value
            # 
            def table_name
              self.name.underscore.pluralize
            end

            ##
            # Return :activerecord
            # 
            def orm
              :datamapper
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
            # For +query+ we mean standard adapter options such as +links+ ...
            # 
            # So a +ext_search+ can be:
            # 
            #   Account.ext_search({:query => "foo", fileds="name,surname,categories.name", :sort => "name", 
            #                       :dir => "asc", :limit => 50, :offset => 10 }, { :links => :categories })
            # 
            def ext_search(params, query={})

              # We build a base struct for have some good results
              result = ExtSearch.new(0, [])

              if params[:query].present? && params[:fields].present?
                # Here we build some like: ["name LIKE ?", "surname LIKE ?"]
                fields  = params[:fields].split(",").collect { |f| "#{f.strip.downcase} LIKE ?" }
                # Here we build some like: ["name LIKE ? OR surname LIKE ?", "%foo%", "%foo%"]
                query[:conditions] = [fields.join(" OR ")].concat(1.upto(fields.length).collect { "%#{params[:query]}%" })
              end

              # Now we can perform a count
              result.count = count(query)

              # First we need to sort our record but we have some problems if we sort for associated tables.
              # 
              # see: http://www.mail-archive.com/datamapper@googlegroups.com/msg01310.html
              # 
              # I can get these values:
              # 
              # * accounts.name
              # * accounts.posts.name
              # * accounts.posts.categories.name
              # 
              # We need to transform in some like [DataMapper::Query::Direction.new(Account.properties[:name], :asc)]
              # 
              if params[:sort].present? && params[:dir].to_s =~ /^(asc|desc)$/i
                values    = params[:sort].to_s.sub(/^#{table_name}\./, "").split(".").collect(&:to_sym)
                property  = values.delete_at(-1) # the last value is always a property
                relation  = values.inject(self) do |relation, value| 
                  raise "Unknow relation #{value} for #{relation}" unless relation.relationships[value]
                  relation.send(value)
                end
                target = relation.respond_to?(:model) ? relation.model.properties[property] : relation.properties[property]
                query[:order] = [::DataMapper::Query::Direction.new(target, params[:dir].to_s.downcase.to_sym)]
              end

              # Now time to limit/offset it
              query[:limit]  = params[:limit].to_i  if params[:limit].to_i > 0
              query[:offset] = params[:start].to_i  if params[:start].to_i > 0

              # Now we can perform ording/limiting
              result.records = all(query)
              result
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
            super
            base.send :include, Padrino::Admin::Orm::Abstract::Account
            base.send :include, ::DataMapper::Validate
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
        end # Account
      end # DataMapper
    end # Orm
  end # Admin
end # Padrino