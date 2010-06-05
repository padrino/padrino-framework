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
  @_shell ||= Thor::Base.shell.new
end

# Load rake tasks from common rake task definition locations
Dir["lib/tasks/**/*.rake"].
  concat(Dir["tasks/**/*.rake"]).
  concat(Dir["{test,spec}/*.rake"]).each  { |ext| load(ext) }

# Loads the Padrino applications mounted within the project
# setting up the required environment for Padrino
task :environment do
  Padrino.mounted_apps.each do |app|
    app.app_object.setup_application!
  end
end

desc "Displays a listing of the named routes within a project"
task :routes, :query, :needs => :environment do |t, args|
  Padrino.mounted_apps.each do |app|
    app_routes = app.app_object.router.routes
    app_routes.reject! { |r| r.named.blank? || r.as_options[:conditions][:request_method].try(:first) == 'HEAD' }
    app_routes.reject! { |r| r.named.to_s !~ /#{args.query}/ } if args.query.present?
    next if app_routes.empty?
    shell.say "\nApplication: #{app.name}", :yellow
    app_routes.map! do |route|
      name_string     = "(#{route.named.to_s.split("_").map { |piece| %Q[:#{piece}] }.join(", ")})"
      request_method = route.as_options[:conditions][:request_method].try(:first)
      [request_method, name_string, route.path]
    end
    app_routes.unshift(["REQUEST", "URL", "PATH"])
    max_col_1 = app_routes.max { |a, b| a[0].size <=> b[0].size }[0].size
    max_col_2 = app_routes.max { |a, b| a[1].size <=> b[1].size }[1].size
    app_routes.each_with_index do |row, i|
      message = [row[1].ljust(max_col_2+2), row[0].center(max_col_1+2), row[2]]
      shell.say("    " + message.join(" "), i==0 ? :bold : nil)
    end
  end
end