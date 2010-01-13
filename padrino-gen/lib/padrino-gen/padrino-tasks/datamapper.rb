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