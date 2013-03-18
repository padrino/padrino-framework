if PadrinoTasks.load?(:minirecord, defined?(MiniRecord))
  namespace :mr do
    desc 'Auto migration of database'
    task :migrate => :environment do
      Dir["models/*.rb"].each do |file_path|
        basename = File.basename(file_path, File.extname(file_path))
        clazz = basename.camelize.constantize
        clazz.auto_upgrade! if clazz.ancestors.include?(ActiveRecord::Base)
      end
      puts "<= mr:migrate executed"
    end
  end

  task 'db:migrate' => 'mr:migrate'
  # task 'db:create'  => 'mr:create'
  # task 'db:drop'    => 'mr:drop'
  # task 'db:reset'   => 'mr:reset'
  # task 'db:setup'   => 'mr:setup'
end
