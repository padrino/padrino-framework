require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require File.dirname(__FILE__) + '/../tasks'

Dir["lib/tasks/**/*.rake"].each { |ext| load(ext) }
Padrino::Tasks.files.flatten.uniq.each { |ext| load(ext) }

def shell
  @_shell ||= Thor::Shell::Basic.new
end

task :environment do
  Padrino.mounted_apps.each do |app|
    Padrino.require_dependency(app.app_file)
    app.app_object.setup_application!
  end
end

desc 'Load the seed data from db/seeds.rb'
task :seed => :environment do
  seed_file = Padrino.root('db', 'seeds.rb')
  load(seed_file) if File.exist?(seed_file)
end