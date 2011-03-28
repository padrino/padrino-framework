def setup_script
  get('https://github.com/padrino/padrino-static/raw/master/js/mootools.js', destination_root("/public/javascripts/mootools-core.js"))
  get('https://github.com/padrino/padrino-static/raw/master/ujs/mootools-ujs.js', destination_root("/public/javascripts/mootools-ujs.js"))
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end