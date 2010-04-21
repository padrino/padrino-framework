require File.expand_path(File.dirname(__FILE__) + '/../tasks')
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

# Load rake tasks from common rake task definition locations
Dir["lib/tasks/**/*.rake"].
  concat(Dir["tasks/**/*.rake"]).
  concat(Dir["{test,spec}/*.rake"]).each  { |ext| load(ext) }

# Loads the Padrino applications mounted within the project
# setting up the required environment for Padrino
task :environment do
  Padrino.mounted_apps.each do |app|
    Padrino.require_dependency(app.app_file)
    app.app_object.setup_application!
  end
end

# Displays a listing of the named routes within a project
# Listing can be optionally scoped by route name
# rake routes routes[accounts]
task :routes, :query, :needs => :environment do |t, args|
  Padrino.mounted_apps.each do |app|
    app_routes = app.app_object.router.routes
    app_routes.reject! { |r| r.named.blank?  || r.conditions[:request_method] == 'HEAD' }
    app_routes.reject! { |r| r.named.to_s !~ /#{args.query}/ } if args.query.present?
    puts "Application: #{app.name}" if app_routes.size > 0
    app_routes.each do |route| 
      url_string = "[#{route.named.to_s.split("_").map { |piece| ":#{piece}" }.join(", ")}]"
      request_method = route.conditions[:request_method]
      puts %Q[    #{url_string} (#{request_method}) => "#{route.original_path}"]
    end
  end
end