def setup_script
  copy_file('templates/scripts/dojo.js', destination_root("/public/javascripts/dojo.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end