if PadrinoTasks.load?(:database, true)
  namespace :db do
    desc 'Load the seed data from db/seeds.rb'
    task :seed => :environment do
      seed_file = Padrino.root('db', 'seeds.rb')
      load(seed_file) if File.exist?(seed_file)
    end

    task :migrate
    task :create
    task :drop
    task :reset
    task :setup
  end

  task :seed => 'db:seed'
end
