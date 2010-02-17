require File.dirname(__FILE__) + '/../tasks'
require 'rake'

Rake.application.instance_variable_set(:@rakefile, __FILE__)

module PadrinoTasks
  def self.init
    Padrino::Tasks.files.flatten.uniq.each { |ext| load(ext) }
    Rake.application.init
    Rake.application.top_level
  end
end

def shell
  @_shell ||= Thor::Shell::Basic.new
end

Dir["lib/tasks/**/*.rake"].concat(Dir["{test,spec}/*.rake"]).each  { |ext| load(ext) }

task :environment do
  Padrino.mounted_apps.each do |app|
    Padrino.require_dependency(app.app_file)
    app.app_object.setup_application!
  end
end

# desc 'Load the seed data from db/seeds.rb'
task :seed => :environment do
  seed_file = Padrino.root('db', 'seeds.rb')
  load(seed_file) if File.exist?(seed_file)
end