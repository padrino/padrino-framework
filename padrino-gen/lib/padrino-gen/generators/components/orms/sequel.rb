SEQUEL = (<<-SEQUEL) unless defined?(SEQUEL)
Sequel::Model.plugin(:schema)
Sequel::Model.raise_on_save_failure = false # Do not throw exceptions on failure
Sequel::Model.db = case Padrino.env
  when :development then Sequel.connect(!DB_DEVELOPMENT!, :loggers => [logger])
  when :production  then Sequel.connect(!DB_PRODUCTION!,  :loggers => [logger])
  when :test        then Sequel.connect(!DB_TEST!,        :loggers => [logger])
end
SEQUEL

def setup_orm
  sequel = SEQUEL
  db = @app_name.underscore
  require_dependencies 'sequel'
  require_dependencies case options[:adapter]
  when 'mysql', 'mysql2'
    sequel.gsub!(/!DB_DEVELOPMENT!/, "\"#{options[:adapter]}://localhost/#{db}_development\"")
    sequel.gsub!(/!DB_PRODUCTION!/, "\"#{options[:adapter]}://localhost/#{db}_production\"")
    sequel.gsub!(/!DB_TEST!/,"\"#{options[:adapter]}://localhost/#{db}_test\"")
    options[:adapter]
  when 'postgres'
    sequel.gsub!(/!DB_DEVELOPMENT!/, "\"postgres://localhost/#{db}_development\"")
    sequel.gsub!(/!DB_PRODUCTION!/, "\"postgres://localhost/#{db}_production\"")
    sequel.gsub!(/!DB_TEST!/,"\"postgres://localhost/#{db}_test\"")
    'pg'
  else
    sequel.gsub!(/!DB_DEVELOPMENT!/,"\"sqlite://\" + Padrino.root('db', \"#{db}_development.db\")")
    sequel.gsub!(/!DB_PRODUCTION!/,"\"sqlite://\" + Padrino.root('db', \"#{db}_production.db\")")
    sequel.gsub!(/!DB_TEST!/,"\"sqlite://\" + Padrino.root('db', \"#{db}_test.db\")")
    'sqlite3'
  end
  create_file("config/database.rb", sequel)
  empty_directory('db/migrate')
end

SQ_MODEL = (<<-MODEL) unless defined?(SQ_MODEL)
class !NAME! < Sequel::Model

end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
  model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
  model_contents = SQ_MODEL.gsub(/!NAME!/, name.to_s.camelize)
  create_file(model_path, model_contents)
end

SQ_MIGRATION = (<<-MIGRATION) unless defined?(SQ_MIGRATION)
class !FILECLASS! < Sequel::Migration
  def up
    !UP!
  end

  def down
    !DOWN!
  end
end
MIGRATION

SQ_MODEL_UP_MG = (<<-MIGRATION).gsub(/^/, '    ') unless defined?(SQ_MODEL_UP_MG)
create_table :!TABLE! do
  primary_key :id
  !FIELDS!
end
MIGRATION

SQ_MODEL_DOWN_MG = (<<-MIGRATION) unless defined?(SQ_MODEL_DOWN_MG)
drop_table :!TABLE!
MIGRATION

def create_model_migration(migration_name, name, columns)
  output_model_migration(migration_name, name, columns,
         :column_format => Proc.new { |field, kind| "#{kind.camelize} :#{field}" },
         :base => SQ_MIGRATION, :up => SQ_MODEL_UP_MG, :down => SQ_MODEL_DOWN_MG)
end

SQ_CHANGE_MG = (<<-MIGRATION).gsub(/^/, '    ') unless defined?(SQ_CHANGE_MG)
alter_table :!TABLE! do
  !COLUMNS!
end
MIGRATION

def create_migration_file(migration_name, name, columns)
  output_migration_file(migration_name, name, columns,
    :base => SQ_MIGRATION, :change_format => SQ_CHANGE_MG,
    :add => Proc.new { |field, kind| "add_column :#{field}, #{kind.camelize}"  },
    :remove => Proc.new { |field, kind| "drop_column :#{field}" }
  )
end
