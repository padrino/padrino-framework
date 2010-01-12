# Reloads classes
def reload!
  Padrino.reload!
end

# Show applications
def applications
  puts "==== List of Mounted Applications ====\n\n"
  Padrino.mounted_apps.each do |app|
    puts " * %-10s mapped to      %s" % [app.name, app.uri_root]
  end
  puts
  Padrino.mounted_apps.collect { |app| "#{app.name} => #{app.uri_root}" }
end

# Load apps
Padrino.mounted_apps.each do |app|
  puts "=> Loading Application #{app.name}"
  Padrino.require_dependency(app.app_file)
  app.app_object.setup_application!
end
