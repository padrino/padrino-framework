def setup_script
  copy_file('templates/scripts/protopak.js', destination_root("/public/javascripts/protopak.js"))
  copy_file('templates/scripts/lowpro.js', destination_root("/public/javascripts/lowpro.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end