def setup_script
  copy_file('templates/scripts/right.js', destination_root("/public/javascripts/right.js"))
  copy_file('templates/ujs/right-ujs.js', destination_root("/public/javascripts/right-ujs.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end
