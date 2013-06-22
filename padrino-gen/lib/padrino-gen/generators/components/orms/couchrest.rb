COUCHREST = (<<-COUCHREST) unless defined?(COUCHREST)
case Padrino.env
  when :development then db_name = '!NAME!_development'
  when :production  then db_name = '!NAME!_production'
  when :test        then db_name = '!NAME!_test'
end

CouchRest::Model::Base.configure do |conf|
  conf.model_type_key = 'type' # compatibility with CouchModel 1.1
  conf.database = CouchRest.database!(db_name)
  conf.environment = Padrino.env
  # conf.connection = {
  #   :protocol => 'http',
  #   :host     => 'localhost',
  #   :port     => '5984',
  #   :prefix   => 'padrino',
  #   :suffix   => nil,
  #   :join     => '_',
  #   :username => nil,
  #   :password => nil
  # }
end
COUCHREST

def setup_orm
  require_dependencies 'couchrest_model', :version => '~>1.1.0'
  require_dependencies 'json_pure'
  create_file("config/database.rb", COUCHREST.gsub(/!NAME!/, @project_name.underscore))
end

CR_MODEL = (<<-MODEL) unless defined?(CR_MODEL)
class !NAME! < CouchRest::Model::Base
  unique_id :id
  # property <name>
  !FIELDS!
end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  field_tuples = options[:fields].map { |value| value.split(":") }
  column_declarations = field_tuples.map { |field, kind| "property :#{field}" }.join("\n  ")
  model_contents = CR_MODEL.gsub(/!NAME!/, name.to_s.underscore.camelize)
  model_contents.gsub!(/!FIELDS!/, column_declarations)
  create_file(model_path, model_contents)
end

def create_model_migration(filename, name, fields)
  # NO MIGRATION NEEDED
end

def create_migration_file(migration_name, name, columns)
  # NO MIGRATION NEEDED
end
