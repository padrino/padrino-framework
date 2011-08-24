def setup_script
  begin
    get('https://github.com/padrino/padrino-static/raw/master/js/mootools.js',  destination_root("/public/javascripts/mootools.js"))
    get('https://github.com/padrino/padrino-static/raw/master/ujs/mootools.js', destination_root("/public/javascripts/mootools-ujs.js"))
  rescue
    copy_file('templates/static/js/mootools.js',  destination_root("/public/javascripts/mootools.js"))
    copy_file('templates/static/ujs/mootools.js', destination_root("/public/javascripts/mootools-ujs.js"))
  end
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end
