def setup_script
  get('https://github.com/padrino/padrino-static/raw/master/js/right.js', destination_root("/public/javascripts/right.js"))
  get('https://github.com/padrino/padrino-static/raw/master/ujs/right-ujs.js', destination_root("/public/javascripts/right-ujs.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end
