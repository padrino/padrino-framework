AR = (<<-AR) unless defined?(AR)
##
# You can use other adapters like:
#
#   ActiveRecord::Base.configurations[:development] = {
#     :adapter   => 'mysql',
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

# Include Active Record class name as root for JSON serialized output.
ActiveRecord::Base.include_root_in_json = true

# Store the full class name (including module namespace) in STI type column.
ActiveRecord::Base.store_full_sti_class = true

# Use ISO 8601 format for JSON serialized times and dates.
ActiveSupport.use_standard_json_time_format = true

# Don't escape HTML entities in JSON, leave that for the #json_escape helper.
# if you're including raw json in an HTML page.
ActiveSupport.escape_html_entities_in_json = false

# Now we can estabilish connection with our db
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Padrino.env])
AR

MYSQL = (<<-MYSQL)
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

MYSQL2 = (<<-MYSQL2)
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

POSTGRES = (<<-POSTGRES)
  :adapter   => 'postgresql',
  :database  => !DB_NAME!,
  :username  => 'root',
  :password  => '',
  :host      => 'localhost',
  :port      => 5432
POSTGRES

SQLITE = (<<-SQLITE)
  :adapter => 'sqlite3',
  :database => !DB_NAME!
SQLITE


def setup_orm
  ar = AR
  db = @app_name.underscore
  case options[:adapter]
  when 'mysql'
    ar.gsub! /!DB_DEVELOPMENT!/, MYSQL.gsub(/!DB_NAME!/,"\"#{db}_development\"")
    ar.gsub! /!DB_PRODUCTION!/, MYSQL.gsub(/!DB_NAME!/,"\"#{db}_production\"")
    ar.gsub! /!DB_TEST!/, MYSQL.gsub(/!DB_NAME!/,"\"#{db}_test\"")
    require_dependencies 'mysql'
  when 'mysql2'
    ar.gsub! /!DB_DEVELOPMENT!/, MYSQL2.gsub(/!DB_NAME!/,"\"#{db}_development\"")
    ar.gsub! /!DB_PRODUCTION!/, MYSQL2.gsub(/!DB_NAME!/,"\"#{db}_production\"")
    ar.gsub! /!DB_TEST!/, MYSQL2.gsub(/!DB_NAME!/,"\"#{db}_test\"")
    require_dependencies 'mysql2'
  when 'postgres'
    ar.gsub! /!DB_DEVELOPMENT!/, POSTGRES.gsub(/!DB_NAME!/,"\"#{db}_development\"")
    ar.gsub! /!DB_PRODUCTION!/, POSTGRES.gsub(/!DB_NAME!/,"\"#{db}_production\"")
    ar.gsub! /!DB_TEST!/, POSTGRES.gsub(/!DB_NAME!/,"\"#{db}_test\"")
    require_dependencies 'pg', :require => 'postgres'
  else
    ar.gsub! /!DB_DEVELOPMENT!/, SQLITE.gsub(/!DB_NAME!/,"Padrino.root('db', \"#{db}_development.db\")")
    ar.gsub! /!DB_PRODUCTION!/, SQLITE.gsub(/!DB_NAME!/,"Padrino.root('db', \"#{db}_production.db\")")
    ar.gsub! /!DB_TEST!/, SQLITE.gsub(/!DB_NAME!/,"Padrino.root('db', \"#{db}_test.db\")")
    require_dependencies 'sqlite3'
  end
  require_dependencies 'activerecord', :require => 'active_record'
  create_file("config/database.rb", ar)
end

AR_MODEL = (<<-MODEL) unless defined?(AR_MODEL)
class !NAME! < ActiveRecord::Base

end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  model_contents = AR_MODEL.gsub(/!NAME!/, name.to_s.camelize)
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

AR_MODEL_UP_MG = (<<-MIGRATION).gsub(/^/, '    ') unless defined?(AR_MODEL_UP_MG)
create_table :!TABLE! do |t|
  !FIELDS!
end
MIGRATION

AR_MODEL_DOWN_MG = (<<-MIGRATION) unless defined?(AR_MODEL_DOWN_MG)
drop_table :!TABLE!
MIGRATION

def create_model_migration(migration_name, name, columns)
  output_model_migration(migration_name, name, columns,
       :base => AR_MIGRATION,
       :column_format => Proc.new { |field, kind| "t.#{kind.underscore.gsub(/_/, '')} :#{field}" },
       :up => AR_MODEL_UP_MG, :down => AR_MODEL_DOWN_MG)
end

AR_CHANGE_MG = (<<-MIGRATION).gsub(/^/, '    ') unless defined?(AR_CHANGE_MG)
change_table :!TABLE! do |t|
  !COLUMNS!
end
MIGRATION

def create_migration_file(migration_name, name, columns)
  output_migration_file(migration_name, name, columns,
    :base => AR_MIGRATION, :change_format => AR_CHANGE_MG,
    :add => Proc.new { |field, kind| "t.#{kind.underscore.gsub(/_/, '')} :#{field}" },
    :remove => Proc.new { |field, kind| "t.remove :#{field}" }
  )
end
