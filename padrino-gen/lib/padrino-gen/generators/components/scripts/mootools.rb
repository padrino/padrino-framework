def setup_script
  begin
    get('https://raw.github.com/padrino/padrino-static/master/js/mootools.js',  destination_root("/public/javascripts/mootools.js"))
    get('https://raw.github.com/padrino/padrino-static/master/ujs/mootools.js', destination_root("/public/javascripts/mootools-ujs.js"))
  rescue
    copy_file('templates/static/js/mootools.js',  destination_root("/public/javascripts/mootools.js"))
    copy_file('templates/static/ujs/mootools.js', destination_root("/public/javascripts/mootools-ujs.js"))
  end
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end
