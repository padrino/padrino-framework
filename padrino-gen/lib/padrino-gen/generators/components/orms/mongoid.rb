MONGOID = (<<-MONGO) unless defined?(MONGOID)
# Connection.new takes host and port
host = 'localhost'
port = Mongo::Connection::DEFAULT_PORT

database_name = case Padrino.env
  when :development then '!NAME!_development'
  when :production  then '!NAME!_production'
  when :test        then '!NAME!_test'
end

Mongoid.database = Mongo::Connection.new(host, port).db(database_name)

# You can also configure Mongoid this way:
# Mongoid.configure do |config|
#   name = @settings["database"]
#   host = @settings["host"]
#   config.master = Mongo::Connection.new.db(name)
#   config.slaves = [
#     Mongo::Connection.new(host, @settings["slave_one"]["port"], :slave_ok => true).db(name),
#     Mongo::Connection.new(host, @settings["slave_two"]["port"], :slave_ok => true).db(name)
#   ]
# end
#
# More installation and setup notes are on http://mongoid.org/.
MONGO

MONGOID3 = (<<-MONGO) unless defined?(MONGOID3)
# Connection.new takes host and port.

host = 'localhost'
port = 27017

database_name = case Padrino.env
  when :development then '!NAME!_development'
  when :production  then '!NAME!_production'
  when :test        then '!NAME!_test'
end

# Use MONGO_URI if it's set as an environmental variable.
Mongoid::Config.sessions =
  if ENV['MONGO_URI']
    {default: {uri: ENV['MONGO_URI'] }}
  else
    {default: {hosts: ["#\{host\}:#\{port\}"], database: database_name}}
  end

# If you want to use a YML file for config, use this instead:
#
#   Mongoid.load!(File.join(Padrino.root, 'config', 'database.yml'), Padrino.env)
#
# And add a config/database.yml file like this:
#   development:
#     sessions:
#       default:
#         database: !NAME!_development
#         hosts:
#           - localhost:27017
#   production:
#     sessions:
#       default:
#         database: !NAME!_production
#         hosts:
#           - localhost:27017
#   test:
#     sessions:
#       default:
#         database: !NAME!_test
#         hosts:
#           - localhost:27017
#
#
# More installation and setup notes are on http://mongoid.org/en/mongoid/docs/installation.html#configuration
MONGO

def setup_orm
  require_dependencies 'mongoid', :version => '~>3.0.0'
  create_file('config/database.rb', MONGOID3.gsub(/!NAME!/, @project_name.underscore))
end

MONGOID_MODEL = (<<-MODEL) unless defined?(MONGOID_MODEL)
class !NAME!
  include Mongoid::Document
  include Mongoid::Timestamps # adds created_at and updated_at fields

  # field <name>, :type => <type>, :default => <value>
  !FIELDS!

  # You can define indexes on documents using the index macro:
  # index :field <, :unique => true>

  # You can create a composite key in mongoid to replace the default id using the key macro:
  # key :field <, :another_field, :one_more ....>
end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  field_tuples = options[:fields].map { |value| value.split(":") }
  column_declarations = field_tuples.map { |field, kind| "field :#{field}, :type => #{kind.underscore.camelize}" }.join("\n  ")
  model_contents = MONGOID_MODEL.gsub(/!NAME!/, name.to_s.underscore.camelize)
  model_contents.gsub!(/!FIELDS!/, column_declarations)
  create_file(model_path, model_contents)
end

def create_model_migration(filename, name, fields)
  # NO MIGRATION NEEDED
end

def create_migration_file(migration_name, name, columns)
  # NO MIGRATION NEEDED
end
