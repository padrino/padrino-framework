if defined?(Sequel)
  namespace :sq do
    namespace :migrate do

      desc "Perform automigration (reset your db data)"
      task :auto => :environment do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate", :target => 0
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate"
        puts "<= sq:migrate:auto executed"
      end

      desc "Perform migration up/down to VERSION"
      task :to, [:version] => :environment do |t, args|
        version = (args[:version] || ENV['VERSION']).to_s.strip
        ::Sequel.extension :migration
        raise "No VERSION was provided" if version.empty?
        ::Sequel::Migrator.apply(Sequel::Model.db, "db/migrate", version.to_i)
        puts "<= sq:migrate:to[#{version}] executed"
      end

      desc "Perform migration up to latest migration available"
      task :up => :environment do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate"
        puts "<= sq:migrate:up executed"
      end

      desc "Perform migration down (erase all data)"
      task :down => :environment do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate", :target => 0
        puts "<= sq:migrate:down executed"
      end
    end
  end
end
