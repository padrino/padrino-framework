MONGOMATIC = (<<-MONGO) unless defined?(MONGOMATIC)

case Padrino.env
  when :development then Mongomatic.db = Mongo::Connection.new.db("!NAME!_development")
  when :production then Mongomatic.db = Mongo::Connection.new.db("!NAME!_production")
  when :test then Mongomatic.db = Mongo::Connection.new.db("!NAME!_test")
end
MONGO

def setup_orm
  mongomatic = MONGOMATIC
  require_dependencies 'mongomatic'
  require_dependencies 'bson_ext', :require => 'mongo'
  create_file("config/database.rb", MONGOMATIC.gsub(/!NAME!/, @project_name.underscore))
end

MONGOMATIC_MODEL = (<<-MODEL) unless defined?(MONGOMATIC_MODEL)
class !NAME! < Mongomatic::Base
  include Mongomatic::Expectations::Helper

  # Mongomatic does not have the traditional
  # model definition that AR/MM/DM et. al. have.
  # Staying true to the "ad-hoc" nature of MongoDB,
  # there are no explicit column definitions in the
  # model file.

  # However you can "fake it" by making a column
  # required using expectations
  # For the sake of padrino g model,
  # we'll assume that any property defined
  # on the command-line is required
  # In the case of Integer types, we'll add
  # the expectation: be_a_number
  # Future enhancement may allow a regex for
  # String datatypes


  # Examples:
  # def validate
  #   expectations do
  #     be_present self['name'], "Name cannot be blank"
  #     be_present self['email'], "Email cannot be blank"
  #     be_present self['age'], "Age cannot be blank"
  #     be_present self['password'], "Password cannot be blank"
  #     be_a_number self['age'], "Age must be a number"
  #     be_of_length self['password'], "Password must be at least 8 characters", :minimum => 8
  #   end
  # end

  # def create_indexes
  #   self.collection.create_index('name', :unique => true)
  #   self.collection.create_index('email', :unique => true)
  #   self.collection.create_index('age')
  # end
  def validate
    expectations do
      !FIELDS!
      !INTEGERS!
    end
  end

end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
    model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
    field_tuples = options[:fields].map { |value| value.split(":") }
    column_declarations = field_tuples.map { |field, kind| "be_present self['#{field}'], '#{field} cannot be blank'" }.join("\n      ")
    # Really ugly oneliner
    integers = field_tuples.select { |col, type| type =~ /[Ii]nteger/ }.map { |field, kind| "be_a_number self['#{field}'], '#{field} must be a number'" }.join("\n ")
    model_contents = MONGOMATIC_MODEL.gsub(/!NAME!/, name.to_s.underscore.camelize)
    model_contents.gsub!(/!FIELDS!/, column_declarations)
    model_contents.gsub!(/!INTEGERS!/, integers)
    create_file(model_path, model_contents)
end

def create_model_migration(filename, name, fields)
  # NO MIGRATION NEEDED
end

def create_migration_file(migration_name, name, columns)
  # NO MIGRATION NEEDED
end
