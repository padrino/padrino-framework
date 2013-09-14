MR = (<<-MR) unless defined?(MR)
ActiveRecord::Base.configurations[:development] = {
!DB_DEVELOPMENT!
}

ActiveRecord::Base.configurations[:production] = {
!DB_PRODUCTION!
}

ActiveRecord::Base.configurations[:test] = {
!DB_TEST!
}

# Setup our logger.
ActiveRecord::Base.logger = logger

# Raise exception on mass assignment protection for Active Record models.
ActiveRecord::Base.mass_assignment_sanitizer = :strict

# Log the query plan for queries taking more than this (works
# with SQLite, MySQL, and PostgreSQL).
ActiveRecord::Base.auto_explain_threshold_in_seconds = 0.5

# Doesn't include Active Record class name as root for JSON serialized output.
ActiveRecord::Base.include_root_in_json = false

# Store the full class name (including module namespace) in STI type column.
ActiveRecord::Base.store_full_sti_class = true

# Use ISO 8601 format for JSON serialized times and dates.
ActiveSupport.use_standard_json_time_format = true

# Don't escape HTML entities in JSON, leave that for the json_escape helper
# if you're including raw JSON in an HTML page.
ActiveSupport.escape_html_entities_in_json = false

# Now we can establish connection with our db.
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Padrino.env])
MR

MYSQL = (<<-MYSQL) unless defined?(MYSQL)
  :adapter   => 'mysql',
  :encoding  => 'utf8',
  :reconnect => true,
  :database  => !DB_NAME!,
  :pool      => 5,
  :username  => 'root',
  :password  => '',
  :host      => 'localhost',
  :socket    => '/tmp/mysql.sock'
MYSQL

MYSQL2 = (<<-MYSQL2) unless defined?(MYSQL2)
  :adapter   => 'mysql2',
  :encoding  => 'utf8',
  :reconnect => true,
  :database  => !DB_NAME!,
  :pool      => 5,
  :username  => 'root',
  :password  => '',
  :host      => 'localhost',
  :socket    => '/tmp/mysql.sock'
MYSQL2

POSTGRES = (<<-POSTGRES) unless defined?(POSTGRES)
  :adapter   => 'postgresql',
  :database  => !DB_NAME!,
  :username  => 'root',
  :password  => '',
  :host      => 'localhost',
  :port      => 5432
POSTGRES

SQLITE = (<<-SQLITE) unless defined?(SQLITE)
  :adapter => 'sqlite3',
  :database => !DB_NAME!
SQLITE
def setup_orm
  ar = MR
  db = @project_name.underscore
  case options[:adapter]
  when 'mysql-gem'
    ar.gsub! /!DB_DEVELOPMENT!/, MYSQL.gsub(/!DB_NAME!/,"'#{db}_development'")
    ar.gsub! /!DB_PRODUCTION!/, MYSQL.gsub(/!DB_NAME!/,"'#{db}_production'")
    ar.gsub! /!DB_TEST!/, MYSQL.gsub(/!DB_NAME!/,"'#{db}_test'")
    require_dependencies 'mysql', :version => "~> 2.8.1"
  when 'mysql', 'mysql2'
    ar.gsub! /!DB_DEVELOPMENT!/, MYSQL2.gsub(/!DB_NAME!/,"'#{db}_development'")
    ar.gsub! /!DB_PRODUCTION!/, MYSQL2.gsub(/!DB_NAME!/,"'#{db}_production'")
    ar.gsub! /!DB_TEST!/, MYSQL2.gsub(/!DB_NAME!/,"'#{db}_test'")
    require_dependencies 'mysql2'
  when 'postgres'
    ar.gsub! /!DB_DEVELOPMENT!/, POSTGRES.gsub(/!DB_NAME!/,"'#{db}_development'")
    ar.gsub! /!DB_PRODUCTION!/, POSTGRES.gsub(/!DB_NAME!/,"'#{db}_production'")
    ar.gsub! /!DB_TEST!/, POSTGRES.gsub(/!DB_NAME!/,"'#{db}_test'")
    require_dependencies 'pg'
  else
    ar.gsub! /!DB_DEVELOPMENT!/, SQLITE.gsub(/!DB_NAME!/,"Padrino.root('db', '#{db}_development.db')")
    ar.gsub! /!DB_PRODUCTION!/, SQLITE.gsub(/!DB_NAME!/,"Padrino.root('db', '#{db}_production.db')")
    ar.gsub! /!DB_TEST!/, SQLITE.gsub(/!DB_NAME!/,"Padrino.root('db', '#{db}_test.db')")
    require_dependencies 'sqlite3'
  end
  require_dependencies 'mini_record'
  create_file('config/database.rb', ar)
  insert_hook('ActiveRecord::Base.auto_upgrade!', :after_load)
  insert_middleware 'ActiveRecord::ConnectionAdapters::ConnectionManagement'
end

MR_MODEL = (<<-MODEL) unless defined?(MR_MODEL)
class !NAME! < ActiveRecord::Base
  # Fields
  !FIELDS!
end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  field_tuples = options[:fields].map { |value| value.split(":") }
  column_declarations = field_tuples.map { |field, kind| "field :#{field}, :as => :#{kind}" }.join("\n  ")
  model_contents = MR_MODEL.gsub(/!NAME!/, name.to_s.underscore.camelize)
  model_contents.gsub!(/!FIELDS!/, column_declarations)
  create_file(model_path, model_contents)
end

def create_model_migration(migration_name, name, columns)
  # NO MIGRATION NEEDED
end

def create_migration_file(migration_name, name, columns)
  # NO MIGRATION NEEDED
end
