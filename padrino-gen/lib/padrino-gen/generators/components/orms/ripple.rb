RIPPLE_DB = (<<-RIAK) unless defined?(RIPPLE_DB)
development:
  http_port: 8098
  pb_port: 8087
  host: localhost

# The test environment has additional keys for configuring the
# Riak::TestServer for your test/spec suite:
#
# * bin_dir specifies the path to the "riak" script that you use to
#           start Riak (just the directory)
# * js_source_dir specifies where your custom Javascript functions for
#           MapReduce should be loaded from. Usually app/mapreduce.
test:
  http_port: 9000
  pb_port: 9002
  host: localhost
  bin_dir: /usr/local/bin   # Default for Homebrew.
  js_source_dir: <%%= Padrino.root + "app/mapreduce" %>

production:
  http_port: 8098
  pb_port: 8087
  host: localhost
RIAK
RIPPLE_CFG = (<<RIAK) unless defined?(RIPPLE_CFG)
# encoding: utf-8

require 'ripple'

if File.exist?(Padrino.root + "config/riak.yml")
  Ripple.load_configuration Padrino.root.join('config', 'riak.yml'), [Padrino.env]
end
RIAK

def setup_orm
  require_dependencies 'ripple'
  create_file("config/riak.yml", RIPPLE_DB.gsub(/!NAME!/, @project_name.underscore))
  create_file("config/database.rb", RIPPLE_CFG)
end

RIPPLE_MODEL = (<<-MODEL) unless defined?(RIPPLE_MODEL)
# encoding: utf-8

class !NAME!
  include Ripple::Document

  # Standart properties
  # property :name, String
  !FIELDS!

  # Relations
  # many :addresses
  # many :friends, :class_name => "Person"
  # one :account
end

MODEL
# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  field_tuples = options[:fields].map { |value| value.split(":") }
  column_declarations = field_tuples.map { |field, kind| "property :#{field}, #{kind.underscore.camelize}" }.join("\n  ")
  model_contents = RIPPLE_MODEL.gsub(/!NAME!/, name.to_s.underscore.camelize)
  model_contents.gsub!(/!FIELDS!/, column_declarations)
  create_file(model_path, model_contents)
end

def create_model_migration(filename, name, fields)
  # NO MIGRATION NEEDED
end

def create_migration_file(migration_name, name, columns)
  # NO MIGRATION NEEDED
end
