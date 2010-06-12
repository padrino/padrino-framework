COUCHREST = (<<-COUCHREST) unless defined?(COUCHREST)
case Padrino.env
  when :development then COUCHDB_NAME = '!NAME!_development'
  when :production  then COUCHDB_NAME = '!NAME!_production'
  when :test        then COUCHDB_NAME = '!NAME!_test'
end
COUCHDB = CouchRest.database!(COUCHDB_NAME)
COUCHREST

def setup_orm
  require_dependencies 'couchrest'
  require_dependencies 'json_pure'
  create_file("config/database.rb", COUCHREST.gsub(/!NAME!/, name.underscore))
  empty_directory('app/models')
end

CR_MODEL = (<<-MODEL) unless defined?(CR_MODEL)
class !NAME! < CouchRest::ExtendedDocument
  include CouchRest::Validation

  use_database COUCHDB

  unique_id :id
  # property <name>
  !FIELDS!
end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  field_tuples = options[:fields].collect { |value| value.split(":") }
  column_declarations = field_tuples.collect { |field, kind| "property :#{field}" }.join("\n  ")
  model_contents = CR_MODEL.gsub(/!NAME!/, name.to_s.camelize)
  model_contents.gsub!(/!FIELDS!/, column_declarations)
  create_file(model_path, model_contents)
end

def create_model_migration(filename, name, fields)
  # NO MIGRATION NEEDED
end

def create_migration_file(migration_name, name, columns)
  # NO MIGRATION NEEDED
end