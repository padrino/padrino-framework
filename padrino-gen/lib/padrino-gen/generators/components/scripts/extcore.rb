def setup_script
  copy_file('templates/scripts/ext-core.js', destination_root("/public/javascripts/ext-core.js"))
  copy_file('templates/ujs/extcore-ujs.js', destination_root("/public/javascripts/ext-ujs.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end