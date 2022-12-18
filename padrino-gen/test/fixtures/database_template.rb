##
# You can use other adapters like:
#
#   ActiveRecord::Base.configurations = {
#     :development => {
#       :adapter   => 'mysql2',
#       :encoding  => 'utf8',
#       :reconnect => true,
#       :database  => 'your_database',
#       :pool      => 5,
#       :username  => 'root',
#       :password  => '',
#       :host      => 'localhost',
#       :socket    => '/tmp/mysql.sock'
#     }
#   }
#
ActiveRecord::Base.configurations = {
  :development => {
    :adapter => 'sqlite3',
    :database => Padrino.root('db', 'sample_project_development.db')

  },
  :production => {
    :adapter => 'sqlite3',
    :database => Padrino.root('db', 'sample_project_production.db')

  },
  :test => {
    :adapter => 'sqlite3',
    :database => Padrino.root('db', 'sample_project_test.db')

  }
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
if ActiveRecord::VERSION::MAJOR.to_i < 6
  ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Padrino.env])
else
  ActiveRecord::Base.establish_connection(Padrino.env)
end
