DM = (<<-DM) unless defined?(DM)
##
# A MySQL connection:
# DataMapper.setup(:default, 'mysql://user:password@localhost/the_database_name')
#
# # A Postgres connection:
# DataMapper.setup(:default, 'postgres://user:password@localhost/the_database_name')
#

DataMapper.logger = logger

case Padrino.env
  when :development then DataMapper.setup(:default, "sqlite3://" + Padrino.root('db', "development.db"))
  when :production  then DataMapper.setup(:default, "sqlite3://" + Padrino.root('db', "production.db"))
  when :test        then DataMapper.setup(:default, "sqlite3://" + Padrino.root('db', "test.db"))
end
DM

def setup_orm
  require_dependencies 'data_objects', 'do_sqlite3', 'datamapper'
  create_file("config/database.rb", DM)
  empty_directory('app/models')
end

DM_MODEL = (<<-MODEL) unless defined?(DM_MODEL)
class !NAME!
  include DataMapper::Resource

  # property <name>, <type>
  property :id, Serial
  !FIELDS!
end
MODEL

def create_model_file(name, fields)
  model_path = destination_root('app/models/', "#{name.to_s.underscore}.rb")
  model_contents = DM_MODEL.gsub(/!NAME!/, name.to_s.downcase.camelize)
  field_tuples = fields.collect { |value| value.split(":") }
  field_tuples.collect! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] } # fix datetime
  column_declarations = field_tuples.collect { |field, kind|"property :#{field}, #{kind.camelize}" }.join("\n  ")
  model_contents.gsub!(/!FIELDS!/, column_declarations)
  create_file(model_path, model_contents)
end

DM_MIGRATION = (<<-MIGRATION) unless defined?(DM_MIGRATION)
migration !VERSION!, :!FILENAME! do
  up do
    !UP!
  end

  down do
    !DOWN!
  end
end
MIGRATION

DM_MODEL_UP_MG =  (<<-MIGRATION) unless defined?(DM_MODEL_UP_MG)
    create_table :!TABLE! do
      column :id, Integer, :serial => true
      !FIELDS!
    end
MIGRATION

DM_MODEL_DOWN_MG =  (<<-MIGRATION) unless defined?(DM_MODEL_DOWN_MG)
drop_table :!TABLE!
MIGRATION

def create_model_migration(migration_name, name, columns)
  output_model_migration(migration_name, name, columns,
       :column_format => Proc.new { |field, kind| "column :#{field}, \"#{kind.upcase}\"" },
       :base => DM_MIGRATION, :up => DM_MODEL_UP_MG, :down => DM_MODEL_DOWN_MG)
end

DM_CHANGE_MG = (<<-MIGRATION) unless defined?(DM_CHANGE_MG)
    modify_table :!TABLE! do
      !COLUMNS!
    end
MIGRATION

def create_migration_file(migration_name, name, columns)
  output_migration_file(migration_name, name, columns,
    :base => DM_MIGRATION, :change_format => DM_CHANGE_MG,
    :add => Proc.new { |field, kind| "add_column :#{field}, #{kind.camelize}"  },
    :remove => Proc.new { |field, kind| "drop_column :#{field}" }
  )
end