def setup_script
  copy_file('templates/scripts/jquery.js', destination_root("/public/javascripts/jquery.js"))
  copy_file('templates/ujs/jquery-ujs.js', destination_root("/public/javascripts/jquery-ujs.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end