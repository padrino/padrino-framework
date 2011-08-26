desc 'Load the seed data from db/seeds.rb'
task :seed => :environment do
  seed_file = Padrino.root('db', 'seeds.rb')
  load(seed_file) if File.exist?(seed_file)
end
