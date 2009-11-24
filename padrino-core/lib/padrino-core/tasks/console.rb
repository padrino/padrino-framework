# Reloads classes
def reload!
  Padrino.reload!
end

# Show applications
def applications
  puts "==== List of Mounted Applications ====\n\n"
  Padrino.mounted_apps.each do |app|
    puts " * '#{app.name}' mapped to '#{app.uri_root}'"
  end
  puts
  Padrino.mounted_apps.collect { |app| "#{app.name} => #{app.uri_root}" }
end

# Load apps
Padrino.mounted_apps.each do |app|
  puts "=> Loading Application #{app.name}"
  Padrino.require_dependency(app.app_file)
  ["models/*.rb", "app/models/*.rb"].each { |p| Padrino.require_dependencies(File.join(app.app_object.root, p)) }
  app.app_object.register(DatabaseSetup) if defined?(DatabaseSetup)
end