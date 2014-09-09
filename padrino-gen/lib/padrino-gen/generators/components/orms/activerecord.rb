AR = (<<-AR) unless defined?(AR)
##
# You can use other adapters like:
#
#   ActiveRecord::Base.configurations[:development] = {
#     :adapter   => 'mysql2',
#     :encoding  => 'utf8',
#     :reconnect => true,
#     :database  => 'your_database',
#     :pool      => 5,
#     :username  => 'root',
#     :password  => '',
#     :host      => 'localhost',
#     :socket    => '/tmp/mysql.sock'
#   }
#
ActiveRecord::Base.configurations[:development] = {
!DB_DEVELOPMENT!
}

ActiveRecord::Base.configurations[:production] = {
!DB_PRODUCTION!
}

ActiveRecord::Base.configurations[:test] = {
!DB_TEST!
}

# Setup our logger
ActiveRecord::Base.logger = logger

if ActiveRecord::VERSION::MAJOR.to_i < 4
  # Raise exception on mass assignment protection for Active Record models.
  ActiveRecord::Base.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL).
  ActiveRecord::Base.auto_explain_threshold_in_seconds = 0.5
end

# Doesn't include Active Record class name as root for JSON serialized output.
ActiveRecord::Base.include_root_in_json = false

# Store the full class name (including module namespace) in STI type column.
ActiveRecord::Base.store_full_sti_class = true

# Use ISO 8601 format for JSON serialized times and dates.
ActiveSupport.use_standard_json_time_format = true

# Don't escape HTML entities in JSON, leave that for the #json_escape helper
# if you're including raw JSON in an HTML page.
ActiveSupport.escape_html_entities_in_json = false

# Now we can establish connection with our db.
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Padrino.env])

# Timestamps are in the utc by default.
ActiveRecord::Base.default_timezone = :utc
AR

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

CONNECTION_POOL_MIDDLEWARE = <<-MIDDLEWARE
class ConnectionPoolManagement
  def initialize(app)
    @app = app
  end

  def call(env)
    ActiveRecord::Base.connection_pool.with_connection { @app.call(env) }
  end
end
MIDDLEWARE

def setup_orm
  ar = AR
  db = @project_name.underscore
  # We're now defaulting to mysql2 since mysql is deprecated
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
  require_dependencies 'activerecord', :require => 'active_record', :version => ">= 3.1"
  create_file("config/database.rb", ar)
  middleware :connection_pool_management, CONNECTION_POOL_MIDDLEWARE
end

AR_MODEL = (<<-MODEL) unless defined?(AR_MODEL)
class !NAME! < ActiveRecord::Base

end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  model_contents = AR_MODEL.gsub(/!NAME!/, name.to_s.underscore.camelize)
  create_file(model_path, model_contents,:skip => true)
end


AR_MIGRATION = (<<-MIGRATION) unless defined?(AR_MIGRATION)
class !FILECLASS! < ActiveRecord::Migration
  def self.up
    !UP!
  end

  def self.down
    !DOWN!
  end
end
MIGRATION

AR_MODEL_UP_MG = (<<-MIGRATION).gsub(/^/,'    ') unless defined?(AR_MODEL_UP_MG)
create_table :!TABLE! do |t|
  !FIELDS!
  t.timestamps
end
MIGRATION

AR_MODEL_DOWN_MG = (<<-MIGRATION) unless defined?(AR_MODEL_DOWN_MG)
drop_table :!TABLE!
MIGRATION

def create_model_migration(migration_name, name, columns)
  output_model_migration(migration_name, name, columns,
    :base          => AR_MIGRATION,
    :column_format => Proc.new { |field, kind| "t.#{kind.underscore.gsub(/_/, '')} :#{field}" },
    :up            => AR_MODEL_UP_MG,
    :down          => AR_MODEL_DOWN_MG
  )
end

AR_CHANGE_MG = (<<-MIGRATION).gsub(/^/, '    ') unless defined?(AR_CHANGE_MG)
change_table :!TABLE! do |t|
  !COLUMNS!
end
MIGRATION

def create_migration_file(migration_name, name, columns)
  output_migration_file(migration_name, name, columns,
    :base          => AR_MIGRATION,
    :change_format => AR_CHANGE_MG,
    :add           => Proc.new { |field, kind| "t.#{kind.underscore.gsub(/_/, '')} :#{field}" },
    :remove        => Proc.new { |field, kind| "t.remove :#{field}" }
  )
end
