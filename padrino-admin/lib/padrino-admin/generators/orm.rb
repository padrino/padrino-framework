module Padrino
  module Admin
    module Generators
      class OrmError < StandardError; end
      class Orm
        attr_reader :klass_name, :klass, :name_plural, :name_singular, :orm

        def initialize(name, orm, columns=nil, column_fields=nil)
          name            = name.to_s
          @klass_name     = name.classify
          @klass          = name.classify.constantize rescue nil
          @name_plural    = name.underscore.pluralize
          @name_singular  = name.underscore
          @orm            = orm.to_sym
          @columns        = columns
          @column_fields  = column_fields
          raise OrmError, "Model #{name} was not found!" if @columns.nil? && @klass.nil?
        end

        def field_type(type)
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
            when :datamapper   then @klass.properties.map { |p| Column.new(p.name, p.primitive) } # Now datamapper returns always nil for property.type
            when :couchrest    then @klass.properties
            when :mongoid      then @klass.fields.values
            when :mongomapper  then @klass.keys.values.reject { |key| key.name == "_id" } # On MongoMapper keys are an hash
            when :sequel       then @klass.db_schema.map { |k,v| v[:type] = :text if v[:db_type] =~ /^text/i; Column.new(k, v[:type]) }
            else raise OrmError, "Adapter #{orm} is not yet supported!"
          end
        end

        def column_fields
          excluded_columns = %w[id created_at updated_at]
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
            when :activerecord, :mongomapper, :mongoid then "#{klass_name}.find(#{params})"
            when :datamapper, :couchrest   then "#{klass_name}.get(#{params})"
            when :sequel then "#{klass_name}[#{params}]"
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
            when :activerecord, :mongomapper, :mongoid, :couchrest then "@#{name_singular}.update_attributes(#{params})"
            when :datamapper then "@#{name_singular}.update(#{params})"
            when :sequel then "@#{name_singular}.modified! && @#{name_singular}.update(#{params})"
            else raise OrmError, "Adapter #{orm} is not yet supported!"
          end
        end

        def destroy
          "#{name_singular}.destroy"
        end
      end # Orm
    end # Generators
  end # Admin
end # Padrino
