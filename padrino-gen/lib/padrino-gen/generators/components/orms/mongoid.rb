MONGOID = <<~MONGO unless defined?(MONGOID)
  # Connection.new takes host and port.

  host = 'localhost'
  port = 27017

  database_name = case Padrino.env
    when :development then '!NAME!_development'
    when :production  then '!NAME!_production'
    when :test        then '!NAME!_test'
  end

  # Use MONGO_URI if it's set as an environmental variable.
  database_settings = if ENV['MONGO_URI']
    { default: { uri: ENV['MONGO_URI'] } }
  else
    { default: { hosts: ["#\{host\}:#\{port\}"], database: database_name} }
  end

  case Mongoid::VERSION
  when /^(3|4)/
    Mongoid::Config.sessions = database_settings
  else
    Mongoid::Config.load_configuration clients: database_settings
  end

  # Mongoid 9 reads times from strings and dates in Time.zone, which only Rails sets.
  # zone_default applies to every thread; change 'UTC' to use another zone.
  Time.zone_default ||= Time.find_zone!('UTC')

  # If you want to use a YML file for config, use this instead:
  #
  #   Mongoid.load!(File.join(Padrino.root, 'config', 'database.yml'), Padrino.env)
  #
  # And add a config/database.yml file like this:
  #   development:
  #     clients: #Replace clients with sessions to work with Mongoid version 3.x or 4.x
  #       default:
  #         database: !NAME!_development
  #         hosts:
  #           - localhost:27017
  #
  #   production:
  #     clients: #Replace clients with sessions to work with Mongoid version 3.x or 4.x
  #       default:
  #         database: !NAME!_production
  #         hosts:
  #           - localhost:27017
  #
  #   test:
  #     clients: #Replace clients with sessions to work with Mongoid version 3.x or 4.x
  #       default:
  #         database: !NAME!_test
  #         hosts:
  #           - localhost:27017
  #
  #
  # More installation and setup notes are on https://docs.mongodb.org/ecosystem/tutorial/mongoid-installation/
MONGO

def setup_orm
  require_dependencies 'mongoid', version: '>= 3.0.0'
  mongoid = MONGOID.gsub(/!NAME!/, @project_name.underscore)
  if falcon_server?
    mongoid = <<~FIBER + mongoid
      # Falcon serves each request in a fiber, so keep Mongoid state per fiber
      # (supported by Mongoid 9.1+ on Ruby 3.2+).
      Mongoid::Config.isolation_level = :fiber if RUBY_VERSION >= '3.2' && Mongoid::Config.respond_to?(:isolation_level=)

    FIBER
  end
  create_file('config/database.rb', mongoid)
end

MONGOID_MODEL = <<~MODEL unless defined?(MONGOID_MODEL)
  class !NAME!
    include Mongoid::Document
    include Mongoid::Timestamps # adds created_at and updated_at fields

    # field <name>, type: <type>, default: <value>
    !FIELDS!

    # You can define indexes on documents using the index macro:
    # index :field <, unique: true>

    # You can create a composite key in mongoid to replace the default id using the key macro:
    # key :field <, :another_field, :one_more ....>
  end
MODEL

# Field kinds from the SQL generators that aren't Mongoid types. Any other kind
# is camelized, so string, integer, boolean, date, time, big_decimal, array,
# hash, symbol or a class name of your own work as before.
unless defined?(MONGOID_FIELD_TYPES)
  MONGOID_FIELD_TYPES = {
    'text' => 'String', 'uuid' => 'String', 'bigint' => 'Integer', 'decimal' => 'BigDecimal',
    'datetime' => 'Time', 'timestamp' => 'Time', 'binary' => 'BSON::Binary', 'json' => 'Object',
    'object_id' => 'BSON::ObjectId'
  }.freeze
end

# A references (or belongs_to) field becomes an association, as in Mongoid's own generator.
# A polymorphic modifier, in any position after the kind, makes it polymorphic.
def mongoid_field(field, kind, modifiers)
  kind = kind.underscore
  if %w[references belongs_to].include?(kind)
    return "belongs_to :#{field}#{', polymorphic: true' if modifiers.include?('polymorphic')}"
  end

  "field :#{field}, type: #{MONGOID_FIELD_TYPES.fetch(kind) { kind.camelize }}"
end

# options => { fields: ['title:string', 'body:string'], app: 'app' }
def create_model_file(name, options = {})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  field_tuples = options[:fields].map { |value| value.split(':') }
  column_declarations = field_tuples.map { |field, kind, *modifiers| mongoid_field(field, kind, modifiers) }.join("\n  ")
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
