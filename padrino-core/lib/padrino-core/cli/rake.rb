require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require File.dirname(__FILE__) + '/../tasks'

Dir["lib/tasks/**/*.rake"].each { |ext| load(ext) }
Padrino::Tasks.files.flatten.uniq.each { |ext| load(ext); puts ext }

task :environment do
  Padrino.logger_env = :test
  Padrino.mounted_apps.each do |app|
    Padrino.require_dependency(app.app_file)
    app.app_object.setup_application!
  end
end