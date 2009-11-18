module Padrino
  module Generators
    module Components
      module Orms
        
        module ActiverecordGen
          
          AR = (<<-AR).gsub(/^ {10}/, '')
          module DatabaseSetup
            def self.registered(app)
              app.configure :development do
                ActiveRecord::Base.establish_connection(
                  :adapter => 'sqlite3',
                  :database => 'your_dev_db_here'
                )
              end

              app.configure :production do
                ActiveRecord::Base.establish_connection(
                  :adapter => 'sqlite3',
                  :database => 'your_production_db_here'
                )
              end

              app.configure :test do
                ActiveRecord::Base.establish_connection(
                  :adapter => 'sqlite3',
                  :database => 'your_test_db_here'
                )
              end
            end
          end
          AR

          RAKE = (<<-RAKE).gsub(/^ {10}/, '')
          require 'sinatra/base'
          require 'active_record'
          
          namespace :db do
            desc "Migrate the database"
            task(:migrate) do
              load 'config/boot.rb'
              ActiveRecord::Base.logger = Logger.new(STDOUT)
              ActiveRecord::Migration.verbose = true
              ActiveRecord::Migrator.migrate("db/migrate")
            end
          end
          RAKE


          def setup_orm
            require_dependencies 'activerecord'
            create_file("config/database.rb", AR)
            create_file("Rakefile", RAKE)
          end
        end
      end
    end
  end
end