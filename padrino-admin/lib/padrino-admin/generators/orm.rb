module Padrino
  module Admin
    ##
    # Contains all admin related generator functionality.
    #
    module Generators
      # Defines a generic exception for the admin ORM handler.
      class OrmError < StandardError; end

      ##
      # Defines the generic ORM management functions used to manipulate data for admin.
      # @private
      class Orm
        attr_reader :klass_name, :klass, :name_plural, :name_singular, :orm

        def initialize(name, orm, columns=nil, column_fields=nil)
          name            = name.to_s
          @klass_name     = name.underscore.camelize
          @klass          = @klass_name.constantize rescue nil
          @name_singular  = name.underscore.gsub(/^.*\//, '') # convert submodules i.e. FooBar::Jank.all # => jank
          @name_plural    = @name_singular.pluralize
          @orm            = orm.to_sym
          @columns        = columns
          @column_fields  = column_fields
          raise OrmError, "Model '#{klass_name}' could not be found!\nPerhaps you would like to run 'bundle exec padrino g model #{klass_name}' to create it first?" if @columns.nil? && @klass.nil?
        end

        def activerecord?
          case orm
          when :activerecord, :minirecord then true
          else false
          end
        end

        def field_type(type)
          type = :string if type.nil? # couchrest-Hack to avoid the next line to fail
          type = type.to_s.demodulize.downcase.to_sym unless type.is_a?(Symbol)
          case type
            when :integer, :float, :decimal   then :text_field
            when :string                      then :text_field
            when :text                        then :text_area
            when :boolean                     then :check_box
            else :text_field
          end
        end

        Column = Struct.new(:name, :type) # for compatibility

        def columns
          @columns ||= case orm
            when :activerecord then @klass.columns
            when :minirecord   then @klass.columns
            when :datamapper   then @klass.properties.map { |p| dm_column(p) }
            when :couchrest    then @klass.properties
            when :mongoid      then @klass.fields.values.reject { |col| %w[_id _type].include?(col.name) }
            when :mongomapper  then @klass.keys.values.reject { |key| key.name == "_id" } # On MongoMapper keys are an hash
            when :sequel       then @klass.db_schema.map { |k,v| v[:type] = :text if v[:db_type] =~ /^text/i; Column.new(k, v[:type]) }
            when :ohm          then @klass.attributes.map { |a| Column.new(a.to_s, :string) } # ohm has strings
            else raise OrmError, "Adapter #{orm} is not yet supported!"
          end
        end

        def dm_column(p)
          case p
          when DataMapper::Property::Text
            Column.new(p.name, :text)
          when DataMapper::Property::Boolean
            Column.new(p.name, :boolean)
          when DataMapper::Property::Integer
            Column.new(p.name, :integer)
          when DataMapper::Property::Decimal
            Column.new(p.name, :decimal)
          when DataMapper::Property::Float
            Column.new(p.name, :float)
          when DataMapper::Property::String
            Column.new(p.name, :string)
          else #if all fails, lets assume its stringish
            Column.new(p.name, :string)
          end
        end

        def column_fields
          excluded_columns = %w[created_at updated_at]
          case orm
            when :mongoid then excluded_columns << '_id'
            else excluded_columns << 'id'
          end

          column_fields    = columns.dup
          column_fields.reject! { |column| excluded_columns.include?(column.name.to_s) }
          @column_fields ||= column_fields.map do |column|
            { :name => column.name, :field_type => field_type(column.type) }
          end
        end

        def all
          "#{klass_name}.all"
        end

        def find(params=nil)
          case orm
            when :activerecord, :minirecord, :mongomapper, :mongoid then "#{klass_name}.find(#{params})"
            when :datamapper, :couchrest then "#{klass_name}.get(#{params})"
            when :sequel, :ohm then "#{klass_name}[#{params}]"
            else raise OrmError, "Adapter #{orm} is not yet supported!"
          end
        end

        def build(params=nil)
          if params
            "#{klass_name}.new(#{params})"
          else
            "#{klass_name}.new"
          end
        end

        def save
          case orm
            when :sequel then "(@#{name_singular}.save rescue false)"
            else "@#{name_singular}.save"
          end
        end

        def update_attributes(params=nil)
          case orm
            when :activerecord, :minirecord, :mongomapper, :mongoid, :couchrest then "@#{name_singular}.update_attributes(#{params})"
            when :datamapper, :ohm then "@#{name_singular}.update(#{params})"
            when :sequel then "@#{name_singular}.modified! && @#{name_singular}.update(#{params})"
            else raise OrmError, "Adapter #{orm} is not yet supported!"
          end
        end

        def destroy
          case orm
            when :ohm then "#{name_singular}.delete"
            else "#{name_singular}.destroy"
          end
        end

        def find_by_ids(params=nil)
          case orm
            when :ohm then "#{klass_name}.fetch(#{params})"
            when :datamapper then "#{klass_name}.all(:id => #{params})"
            when :sequel then "#{klass_name}.where(:id => #{params})"
            when :mongoid then "#{klass_name}.find(#{params})"
            when :couchrest then "#{klass_name}.all(:keys => #{params})"
            else find(params)
          end
        end

        def multiple_destroy(params=nil)
          case orm
            when :ohm then "#{params}.each(&:delete)"
            when :sequel then  "#{params}.destroy"
            when :datamapper then "#{params}.destroy"
            when :couchrest, :mongoid, :mongomapper then "#{params}.each(&:destroy)"
            else "#{klass_name}.destroy #{params}"
          end
        end

        def has_error(field)
          case orm
            when :datamapper, :ohm, :sequel then "@#{name_singular}.errors.key?(:#{field}) && @#{name_singular}.errors[:#{field}].count > 0"
            else "@#{name_singular}.errors.include?(:#{field})"
          end
        end

      end # Orm
    end # Generators
  end # Admin
end # Padrino
