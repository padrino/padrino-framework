def setup_script
  get('https://github.com/padrino/padrino-static/raw/master/js/dojo.js',  destination_root("/public/javascripts/dojo.js"))
  get('https://github.com/padrino/padrino-static/raw/master/ujs/dojo-ujs.js', destination_root("/public/javascripts/dojo-ujs.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end