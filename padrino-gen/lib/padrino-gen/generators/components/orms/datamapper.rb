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
# # Setup DataMapper using config/database.yml
# DataMapper.setup(:default, YAML.load_file(Padrino.root('config/database.yml'))[RACK_ENV])
#
# config/database.yml file:
#
# ---
# development: &defaults
#   adapter: mysql
#   database: example_development
#   username: user
#   password: Pa55w0rd
#   host: 127.0.0.1
#
# test:
#   <<: *defaults
#   database: example_test
#
# production:
#   <<: *defaults
#   database: example_production
#

DataMapper.logger = logger
DataMapper::Property::String.length(255)

case Padrino.env
  when :development then DataMapper.setup(:default, !DB_DEVELOPMENT!)
  when :production  then DataMapper.setup(:default, !DB_PRODUCTION!)
  when :test        then DataMapper.setup(:default, !DB_TEST!)
end
DM

IDENTITY_MAP_MIDDLEWARE = <<-MIDDLEWARE
class IdentityMap
  def initialize(app, name = :default)
    @app = app
    @name = name.to_sym
  end

  def call(env)
    ::DataMapper.repository(@name) do
      @app.call(env)
    end
  end
end
MIDDLEWARE

def setup_orm
  dm = DM
  db = @project_name.underscore
  %w(
    dm-core
    dm-types
    dm-aggregates
    dm-constraints
    dm-migrations
    dm-timestamps
    dm-validations
  ).each { |dep| require_dependencies dep }

  begin
    case adapter ||= options[:adapter]
    when 'mysql', 'mysql2'
      dm.gsub!(/!DB_DEVELOPMENT!/,"\"mysql://root@localhost/#{db}_development\"")
      dm.gsub!(/!DB_PRODUCTION!/,"\"mysql://root@localhost/#{db}_production\"")
      dm.gsub!(/!DB_TEST!/,"\"mysql://root@localhost/#{db}_test\"")
      require_dependencies 'dm-mysql-adapter'
    when 'postgres'
      dm.gsub!(/!DB_DEVELOPMENT!/,"\"postgres://root@localhost/#{db}_development\"")
      dm.gsub!(/!DB_PRODUCTION!/,"\"postgres://root@localhost/#{db}_production\"")
      dm.gsub!(/!DB_TEST!/,"\"postgres://root@localhost/#{db}_test\"")
      require_dependencies 'dm-postgres-adapter'
    when 'sqlite'
      dm.gsub!(/!DB_DEVELOPMENT!/,"\"sqlite3://\" + Padrino.root('db', \"#{db}_development.db\")")
      dm.gsub!(/!DB_PRODUCTION!/,"\"sqlite3://\" + Padrino.root('db', \"#{db}_production.db\")")
      dm.gsub!(/!DB_TEST!/,"\"sqlite3://\" + Padrino.root('db', \"#{db}_test.db\")")
      require_dependencies 'dm-sqlite-adapter'
    else
      say "Failed to generate `config/database.rb` for ORM adapter `#{options[:adapter]}`", :red
      fail ArgumentError
    end
  rescue ArgumentError
    adapter = ask("Please, choose a proper adapter:", :limited_to => %w[mysql mysql2 postgres sqlite])
    retry
  end

  create_file("config/database.rb", dm)
  insert_hook("DataMapper.finalize", :after_load)
  middleware :identity_map, IDENTITY_MAP_MIDDLEWARE
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
  model_contents = DM_MODEL.gsub(/!NAME!/, name.to_s.underscore.camelize)
  field_tuples = options[:fields].map { |value| value.split(":") }
  field_tuples.map! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] } # fix datetime
  column_declarations = field_tuples.map { |field, kind|"property :#{field}, #{kind.underscore.camelize}" }.join("\n  ")
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
       :column_format => Proc.new { |field, kind| "column :#{field}, DataMapper::Property::#{kind.classify}#{', :length => 255' if kind =~ /string/i}" },
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
