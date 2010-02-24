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
          raise OrmError, "Model #{name} not found!" if @columns.nil? && @klass.nil?
        end

        def field_type(type)
          case type
            when :integer, :float, :decimal   then :text_field
            when :string                      then :text_field
            when :text                        then :text_area
            when :boolean                     then :check_box
            else :text_field
          end
        end

        def columns
          @columns ||= case orm
            when :activerecord then @klass.columns
            when :datamapper   then @klass.properties
            when :mongomapper  then @klass.keys.values.reject { |key| key.name == "_id" } # On MongoMapper keys are an hash
            else raise OrmError, "Adapter #{orm} not yet supported!"
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
            when :activerecord, :mongomapper then "#{klass_name}.find(#{params})"
            when :datamapper   then "#{klass_name}.get(#{params})"
            else raise OrmError, "Adapter #{orm} not yet supported!"
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
          "#{name_singular}.save"
        end

        def update_attributes(params=nil)
          case orm
            when :activerecord, :mongomapper then "#{name_singular}.update_attributes(#{params})"
            when :datamapper   then "#{name_singular}.update(#{params})"
            else raise OrmError, "Adapter #{orm} not yet supported!"
          end
        end

        def destroy
          "#{name_singular}.destroy"
        end
      end # Orm
    end # Generators
  end # Admin
end # Padrino