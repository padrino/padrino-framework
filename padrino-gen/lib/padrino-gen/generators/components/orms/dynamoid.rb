DYNAMOID = (<<-DYNAMOID) unless defined?(DYNAMOID)

AWS.config({
  :access_key_id => ENV['AWS_ACCESS_KEY'],
  :secret_access_key => ENV['AWS_SECRET_KEY'],
  :dynamo_db_endpoint => 'dynamodb.ap-southeast-1.amazonaws.com'
})

Dynamoid.configure do |config|
  config.adapter = 'aws_sdk' # This adapter establishes a connection to the DynamoDB servers using Amazon's own AWS gem.
  config.read_capacity = 100 # Read capacity for your tables
  config.write_capacity = 20 # Write capacity for your tables
end

# If you use mock in testing [for example in case of using fake_dynamo],
# the way is as following:
#
#   - install fake_dynamo
#     gem install fake_dynamo --version 0.1.3
#   - run
#     fake_dynamo --port 4567
# 
# And then setting for AWS.config is as following:
# 
#   AWS.config({
#     :access_key_id => 'xxx', # everything is ok
#     :secret_access_key => 'xxx', # everything is ok
#     :dynamo_db_endpoint => 'localhost', # fake_dynamo runs hostname
#     :dynamo_db_port => 4567, # fake_dynamo listens port
#     :use_ssl => false # fake_dynamo don't speak ssl
#   })
#
# Additional information on https://github.com/ananthakumaran/fake_dynamo
DYNAMOID

def setup_orm
  require_dependencies 'aws-sdk'
  require_dependencies 'dynamoid', :version => '~>0.7.1'
  create_file("config/database.rb", DYNAMOID.gsub(/!NAME!/, @project_name.underscore))
end

DYNAMOID_MODEL = (<<-MODEL) unless defined?(DYNAMOID_MODEL)
class !NAME!
  include Dynamoid::Document

  !FIELDS!

end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  field_tuples = options[:fields].map { |value| value.split(":") }
  column_declarations = field_tuples.map { |field, kind| "field :#{field}, :#{kind}" }.join("\n  ")
  model_contents = DYNAMOID_MODEL.gsub(/!NAME!/, name.to_s.underscore.camelize)
  model_contents.gsub!(/!FIELDS!/, column_declarations)
  create_file(model_path, model_contents)
end

def create_model_migration(filename, name, fields)
  # NO MIGRATION NEEDED
end

def create_migration_file(migration_name, name, columns)
  # NO MIGRATION NEEDED
end
