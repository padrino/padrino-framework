if defined?(MiniRecord)
  namespace :mr do
    desc "Auto migration of database"
    task :migrate => :environment do
      Dir["models/*.rb"].each do |file_path|
        basename = File.basename(file_path, File.extname(file_path))
        clazz = basename.camelize.constantize
        clazz.auto_upgrade! if clazz.ancestors.include?(ActiveRecord::Base)
      end
      puts "<= mr:migrate executed"
    end
  end
end
