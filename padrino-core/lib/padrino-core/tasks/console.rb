# Reloads classes
def reload!
  Padrino.reload!
  true
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
  Padrino.load_dependency(app.app_file)
end