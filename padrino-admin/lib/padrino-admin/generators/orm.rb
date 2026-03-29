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
      class Orm
        attr_reader :klass_name, :klass, :name_plural, :name_singular, :orm, :name_param

        def initialize(name, orm, columns = nil, column_fields = nil)
          name            = name.to_s
          @klass_name     = name.underscore.camelize
          @klass          = @klass_name.constantize rescue nil
          @name_param     = name.underscore.gsub('/', '_')
          @name_singular  = name.underscore.gsub(%r{^.*/}, '') # convert submodules i.e. FooBar::Jank.all # => jank
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
          type = :string if type.nil?
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
          @columns ||=
            case orm
            when :activerecord then @klass.columns
            when :minirecord   then @klass.columns
            when :mongoid      then @klass.fields.values.reject { |col| %w[_id _type].include?(col.name) }
            when :sequel       then @klass.db_schema.map { |k, v| v[:type] = :text if v[:db_type] =~ /^text/i; Column.new(k, v[:type]) }
            when :ohm          then @klass.attributes.map { |a| Column.new(a.to_s, :string) } # ohm has strings
            when :dynamoid     then @klass.attributes.map { |k, v| Column.new(k.to_s, v[:type]) }
            else raise OrmError, "Adapter #{orm} is not yet supported!"
            end
        end

        def column_fields
          excluded_columns = %w[created_at updated_at] << (orm == :mongoid ? '_id' : 'id')
          column_fields    = columns.dup
          column_fields.reject! { |column| excluded_columns.include?(column.name.to_s) }
          @column_fields ||= column_fields.map do |column|
            { name: column.name, field_type: field_type(column.type) }
          end
        end

        def all
          "#{klass_name}.all"
        end

        def find(params = nil)
          case orm
          when :activerecord, :minirecord, :mongoid, :dynamoid then "#{klass_name}.find(#{params})"
          when :sequel, :ohm then "#{klass_name}[#{params}]"
          else raise OrmError, "Adapter #{orm} is not yet supported!"
          end
        end

        def build(params = nil)
          if params
            "#{klass_name}.new(#{params})"
          else
            "#{klass_name}.new"
          end
        end

        def save
          orm == :sequel ? "(@#{name_singular}.save rescue false)" : "@#{name_singular}.save"
        end

        def update_attributes(params = nil)
          case orm
          when :mongoid, :dynamoid then "@#{name_singular}.update_attributes(#{params})"
          when :activerecord, :minirecord, :ohm then "@#{name_singular}.update(#{params})"
          when :sequel then "@#{name_singular}.modified! && @#{name_singular}.update(#{params})"
          else raise OrmError, "Adapter #{orm} is not yet supported!"
          end
        end

        def destroy
          orm == :ohm ? "#{name_singular}.delete" : "#{name_singular}.destroy"
        end

        def find_by_ids(params = nil)
          case orm
          when :ohm then "#{klass_name}.fetch(#{params})"
          when :sequel then "#{klass_name}.where(id: #{params})"
          when :mongoid then "#{klass_name}.find(#{params})"
          when :dynamoid then "#{klass_name}.find(#{params})"
          else find(params)
          end
        end

        def multiple_destroy(params = nil)
          case orm
          when :ohm then "#{params}.each(&:delete)"
          when :sequel then "#{params}.destroy"
          when :mongoid, :dynamoid then "#{params}.each(&:destroy)"
          else "#{klass_name}.destroy #{params}"
          end
        end

        def has_error(field)
          case orm
          when :ohm, :sequel then "@#{name_singular}.errors.key?(:#{field}) && @#{name_singular}.errors[:#{field}].count > 0"
          else "@#{name_singular}.errors.include?(:#{field})"
          end
        end
      end
    end
  end
end
