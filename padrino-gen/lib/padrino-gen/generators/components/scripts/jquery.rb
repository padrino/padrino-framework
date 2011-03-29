def setup_script
  get('https://github.com/padrino/padrino-static/raw/master/js/jquery.js', destination_root("/public/javascripts/jquery.js"))
  get('https://github.com/padrino/padrino-static/raw/master/ujs/jquery-ujs.js', destination_root("/public/javascripts/jquery-ujs.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end