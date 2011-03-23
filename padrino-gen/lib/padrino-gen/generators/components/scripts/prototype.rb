def setup_script
  get('https://github.com/padrino/padrino-static/raw/master/js/protopak.js', destination_root("/public/javascripts/protopak.js"))
  get('https://github.com/padrino/padrino-static/raw/master/js/lowpro.js', destination_root("/public/javascripts/lowpro.js"))
  get('https://github.com/padrino/padrino-static/raw/master/ujs/prototype-ujs.js', destination_root("/public/javascripts/prototype-ujs.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end