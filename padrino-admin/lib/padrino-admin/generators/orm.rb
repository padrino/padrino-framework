module Padrino
  module Admin
    ##
    # Contains all admin related generator functionality.
    #
    module Generators
      # Defines a generic exception for the admin ORM handler. A Thor::Error, so the
      # generators print its message without a backtrace and exit with status 1.
      class OrmError < Thor::Error; end

      ##
      # Defines the generic ORM management functions used to manipulate data for admin.
      class Orm
        MODEL_BASES = {
          activerecord: 'ActiveRecord::Base',
          mongoid: 'Mongoid::Document',
          sequel: 'Sequel::Model'
        }.freeze

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
        end

        # Raises OrmError when the model is missing or does not belong to the project's orm. Only
        # needed when reading the model's columns to generate a page, so destroying a page skips it.
        def check_model_orm
          return unless @columns.nil?
          raise OrmError, "Model '#{klass_name}' could not be found!\nPerhaps you would like to run 'bundle exec padrino g model #{klass_name}' to create it first?" if @klass.nil?

          base = MODEL_BASES[orm]
          return if base.nil? || @klass.ancestors.any? { |mod| mod.name == base }

          raise OrmError, "Model '#{klass_name}' is not based on #{base} but the project orm is #{orm}!\nCheck the orm in your .components file."
        end

        def activerecord?
          orm == :activerecord
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
            when :mongoid      then @klass.fields.values.reject { |col| %w[_id _type].include?(col.name) }
            when :sequel       then @klass.db_schema.map { |k, v| v[:type] = :text if v[:db_type] =~ /^text/i; Column.new(k, v[:type]) }
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
          when :activerecord, :mongoid then "#{klass_name}.find(#{params})"
          when :sequel then "#{klass_name}[#{params}]"
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
          when :mongoid then "@#{name_singular}.update_attributes(#{params})"
          when :activerecord then "@#{name_singular}.update(#{params})"
          when :sequel then "@#{name_singular}.modified! && @#{name_singular}.update(#{params})"
          else raise OrmError, "Adapter #{orm} is not yet supported!"
          end
        end

        def destroy
          "#{name_singular}.destroy"
        end

        def find_by_ids(params = nil)
          case orm
          when :sequel then "#{klass_name}.where(id: #{params})"
          when :mongoid then "#{klass_name}.find(#{params})"
          else find(params)
          end
        end

        def multiple_destroy(params = nil)
          case orm
          when :sequel then "#{params}.destroy"
          when :mongoid then "#{params}.each(&:destroy)"
          else "#{klass_name}.destroy #{params}"
          end
        end

        def has_error(field)
          case orm
          when :sequel then "@#{name_singular}.errors.key?(:#{field}) && @#{name_singular}.errors[:#{field}].count > 0"
          else "@#{name_singular}.errors.include?(:#{field})"
          end
        end
      end
    end
  end
end
