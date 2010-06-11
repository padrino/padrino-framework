def setup_script
  copy_file('templates/scripts/dojo.js', destination_root("/public/javascripts/dojo.js"))
  copy_file('templates/ujs/dojo-ujs.js', destination_root("/public/javascripts/dojo-ujs.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end