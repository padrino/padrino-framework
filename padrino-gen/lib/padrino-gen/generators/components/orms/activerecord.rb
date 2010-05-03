AR = (<<-AR).gsub(/^ {10}/, '') unless defined?(AR)
##
# You can use other adapters like:
#
#   ActiveRecord::Base.configurations[:development] = {
#     :adapter   => 'mysql',
#     :encoding  => 'utf8',
#     :reconnect => false,
#     :database  => 'your_database',
#     :pool      => 5,
#     :username  => 'root',
#     :password  => '',
#     :host      => 'localhost',
#     :socket    => '/tmp/mysql.sock'
#   }
#
ActiveRecord::Base.configurations[:development] = {
  :adapter => 'sqlite3',
  :database => Padrino.root('db', "development.db")
}

ActiveRecord::Base.configurations[:production] = {
  :adapter => 'sqlite3',
  :database => Padrino.root('db', "production.db")
}

ActiveRecord::Base.configurations[:test] = {
  :adapter => 'sqlite3',
  :database => Padrino.root('db', "test.db")
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

def setup_orm
  require_dependencies 'sqlite3-ruby', :require => 'sqlite3'
  require_dependencies 'activerecord', :require => 'active_record'
  create_file("config/database.rb", AR)
  empty_directory('app/models')
end

AR_MODEL = (<<-MODEL).gsub(/^ {10}/, '') unless defined?(AR_MODEL)
class !NAME! < ActiveRecord::Base

end
MODEL

def create_model_file(name, fields)
  model_path = destination_root('app/models/', "#{name.to_s.underscore}.rb")
  model_contents = AR_MODEL.gsub(/!NAME!/, name.to_s.downcase.camelize)
  create_file(model_path, model_contents,:skip => true)
end

AR_MIGRATION = (<<-MIGRATION).gsub(/^ {10}/, '') unless defined?(AR_MIGRATION)
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

AR_MODEL_DOWN_MG = (<<-MIGRATION).gsub(/^ {10}/, '') unless defined?(AR_MODEL_DOWN_MG)
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