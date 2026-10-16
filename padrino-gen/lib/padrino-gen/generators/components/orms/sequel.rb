SEQUEL = <<~SEQUEL unless defined?(SEQUEL)
  Sequel::Model.raise_on_save_failure = false # Do not throw exceptions on failure
  # test: false connects on first use, so rake sq:create can run before the database exists.
  Sequel::Model.db = case Padrino.env
    when :development then Sequel.connect(!DB_DEVELOPMENT!, loggers: [logger], test: false)
    when :production  then Sequel.connect(!DB_PRODUCTION!,  loggers: [logger], test: false)
    when :test        then Sequel.connect(!DB_TEST!,        loggers: [logger], test: false)
  end
SEQUEL

def setup_orm
  sequel = SEQUEL.dup
  db = @project_name.underscore
  require_dependencies 'sequel'

  case resolve_valid_adapter
  when 'mysql-gem'
    sequel.gsub!(/!DB_DEVELOPMENT!/, "\"mysql://localhost/#{db}_development\"")
    sequel.gsub!(/!DB_PRODUCTION!/, "\"mysql://localhost/#{db}_production\"")
    sequel.gsub!(/!DB_TEST!/, "\"mysql://localhost/#{db}_test\"")
    require_dependencies 'mysql', version: '~> 2.8.1'
  when 'mysql', 'mysql2'
    sequel.gsub!(/!DB_DEVELOPMENT!/, "\"mysql2://localhost/#{db}_development\"")
    sequel.gsub!(/!DB_PRODUCTION!/, "\"mysql2://localhost/#{db}_production\"")
    sequel.gsub!(/!DB_TEST!/, "\"mysql2://localhost/#{db}_test\"")
    require_dependencies 'mysql2'
  when 'postgres'
    sequel.gsub!(/!DB_DEVELOPMENT!/, "\"postgres://localhost/#{db}_development\"")
    sequel.gsub!(/!DB_PRODUCTION!/, "\"postgres://localhost/#{db}_production\"")
    sequel.gsub!(/!DB_TEST!/, "\"postgres://localhost/#{db}_test\"")
    require_dependencies 'pg'
  when 'sqlite'
    sequel.gsub!(/!DB_DEVELOPMENT!/, "\"sqlite://db/#{db}_development.db\"")
    sequel.gsub!(/!DB_PRODUCTION!/, "\"sqlite://db/#{db}_production.db\"")
    sequel.gsub!(/!DB_TEST!/,       "\"sqlite://db/#{db}_test.db\"")
    require_dependencies 'sqlite3'
  end

  if falcon_server?
    sequel = <<~FIBER + sequel
      # Falcon serves each request in a fiber, so give each fiber its own connection.
      Sequel.extension :fiber_concurrency

    FIBER
  end

  create_file('config/database.rb', sequel)
  empty_directory('db/migrate')
end

SQ_MODEL = <<~MODEL unless defined?(SQ_MODEL)
  class !NAME! < Sequel::Model

  end
MODEL

# options => { fields: ['title:string', 'body:string'], app: 'app' }
def create_model_file(name, options = {})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  model_contents = SQ_MODEL.gsub(/!NAME!/, name.to_s.underscore.camelize)
  create_file(model_path, model_contents)
end

SQ_MIGRATION = <<~MIGRATION unless defined?(SQ_MIGRATION)
  Sequel.migration do
    up do
      !UP!
    end

    down do
      !DOWN!
    end
  end
MIGRATION

SQ_MODEL_UP_MG = <<~MIGRATION.gsub(/^/, '    ') unless defined?(SQ_MODEL_UP_MG)
  create_table :!TABLE! do
    primary_key :id
    !FIELDS!
  end
MIGRATION

SQ_MODEL_DOWN_MG = <<~MIGRATION unless defined?(SQ_MODEL_DOWN_MG)
  drop_table :!TABLE!
MIGRATION

def create_model_migration(migration_name, name, columns)
  output_model_migration(
    migration_name, name, columns,
    column_format: proc { |field, kind| "#{kind.underscore.camelize} :#{field}" },
    base: SQ_MIGRATION,
    up: SQ_MODEL_UP_MG,
    down: SQ_MODEL_DOWN_MG
  )
end

SQ_CHANGE_MG = <<~MIGRATION.gsub(/^/, '    ') unless defined?(SQ_CHANGE_MG)
  alter_table :!TABLE! do
    !COLUMNS!
  end
MIGRATION

# Sequel's generic Ruby types. add_column takes any other kind, such as text or boolean, as a type name.
SQ_GENERIC_TYPES = %w[String Integer Float Numeric BigDecimal Date DateTime Time File TrueClass FalseClass].freeze unless defined?(SQ_GENERIC_TYPES)

def sq_column_type(kind)
  type = kind.underscore.camelize
  SQ_GENERIC_TYPES.include?(type) ? type : ":#{kind.underscore}"
end

def create_migration_file(migration_name, name, columns)
  output_migration_file(
    migration_name, name, columns,
    base: SQ_MIGRATION, change_format: SQ_CHANGE_MG,
    add: proc { |field, kind| "add_column :#{field}, #{sq_column_type(kind)}" },
    remove: proc { |field, _kind| "drop_column :#{field}" }
  )
end
