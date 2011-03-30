def setup_script
  get('https://github.com/padrino/padrino-static/raw/master/js/ext.js', destination_root("/public/javascripts/ext.js"))
  get('https://github.com/padrino/padrino-static/raw/master/ujs/extcore-ujs.js', destination_root("/public/javascripts/ext-ujs.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end