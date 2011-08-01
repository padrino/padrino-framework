DM = (<<-DM) unless defined?(DM)
##
# A MySQL connection:
# DataMapper.setup(:default, 'mysql://user:password@localhost/the_database_name')
#
# # A Postgres connection:
# DataMapper.setup(:default, 'postgres://user:password@localhost/the_database_name')
#
# # A Sqlite3 connection
# DataMapper.setup(:default, "sqlite3://" + Padrino.root('db', "development.db"))
#

DataMapper.logger = logger
DataMapper::Property::String.length(255)

case Padrino.env
  when :development then DataMapper.setup(:default, !DB_DEVELOPMENT!)
  when :production  then DataMapper.setup(:default, !DB_PRODUCTION!)
  when :test        then DataMapper.setup(:default, !DB_TEST!)
end
DM

def setup_orm
  dm = DM
  db = @app_name.underscore
  %w(
    dm-core
    dm-aggregates
    dm-constraints
    dm-migrations
    dm-timestamps
    dm-validations
  ).each { |dep| require_dependencies dep }
  require_dependencies case options[:adapter]
    when 'mysql'
      dm.gsub!(/!DB_DEVELOPMENT!/,"\"mysql://root@localhost/#{db}_development\"")
      dm.gsub!(/!DB_PRODUCTION!/,"\"mysql://root@localhost/#{db}_production\"")
      dm.gsub!(/!DB_TEST!/,"\"mysql://root@localhost/#{db}_test\"")
      'dm-mysql-adapter'
    when 'postgres'
      dm.gsub!(/!DB_DEVELOPMENT!/,"\"postgres://root@localhost/#{db}_development\"")
      dm.gsub!(/!DB_PRODUCTION!/,"\"postgres://root@localhost/#{db}_production\"")
      dm.gsub!(/!DB_TEST!/,"\"postgres://root@localhost/#{db}_test\"")
      'dm-postgres-adapter'
    else
      dm.gsub!(/!DB_DEVELOPMENT!/,"\"sqlite3://\" + Padrino.root('db', \"#{db}_development.db\")")
      dm.gsub!(/!DB_PRODUCTION!/,"\"sqlite3://\" + Padrino.root('db', \"#{db}_production.db\")")
      dm.gsub!(/!DB_TEST!/,"\"sqlite3://\" + Padrino.root('db', \"#{db}_test.db\")")
      'dm-sqlite-adapter'
  end

  create_file("config/database.rb", dm)
  insert_hook("DataMapper.finalize", :after_load)
end

DM_MODEL = (<<-MODEL) unless defined?(DM_MODEL)
class !NAME!
  include DataMapper::Resource

  # property <name>, <type>
  property :id, Serial
  !FIELDS!
end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  model_contents = DM_MODEL.gsub(/!NAME!/, name.to_s.camelize)
  field_tuples = options[:fields].map { |value| value.split(":") }
  field_tuples.map! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] } # fix datetime
  column_declarations = field_tuples.map { |field, kind|"property :#{field}, #{kind.camelize}" }.join("\n  ")
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

DM_MODEL_UP_MG =  (<<-MIGRATION).gsub(/^/, '    ') unless defined?(DM_MODEL_UP_MG)
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
       :column_format => Proc.new { |field, kind| "column :#{field}, #{kind.classify}#{', :length => 255' if kind =~ /string/i}" },
       :base => DM_MIGRATION, :up => DM_MODEL_UP_MG, :down => DM_MODEL_DOWN_MG)
end

DM_CHANGE_MG = (<<-MIGRATION).gsub(/^/, '    ') unless defined?(DM_CHANGE_MG)
modify_table :!TABLE! do
  !COLUMNS!
end
MIGRATION

def create_migration_file(migration_name, name, columns)
  output_migration_file(migration_name, name, columns,
    :base => DM_MIGRATION, :change_format => DM_CHANGE_MG,
    :add => Proc.new { |field, kind| "add_column :#{field}, #{kind.classify}" },
    :remove => Proc.new { |field, kind| "drop_column :#{field}" }
  )
end
