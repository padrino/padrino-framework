require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

Dir["lib/tasks/**/*.rake"].each { |ext| load(ext) }

# TODO: require here padrino-gen rake db:migrate, padrino-routes rake routes etc...

class Padrino::Tasks::RakeFile
  cattr_accessor :boot_file
end

task :environment do
  require Padrino::Tasks::RakeFile.boot_file
  Padrino.logger_env = :test
  Padrino.mounted_apps.each do |app|
    Padrino.require_dependency(app.app_file)
    app.app_object.setup_application!
  end
end

if defined?(DataMapper)
  namespace :dm do
    desc "DataMapper: perform migration (reset your db data)"
    task :migrate => :environment do
      DataMapper.auto_migrate!
      puts "=> db:migrate executed"
    end

    desc "DataMapper: perform upgrade (with a no-destructive way)"
    task :upgrade => :environment do
      DataMapper.auto_upgrade!
      puts "=> db:upgrade executed"
    end
  end
end