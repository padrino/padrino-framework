def setup_script
  begin
    get('https://raw.github.com/padrino/padrino-static/master/js/right.js',  destination_root("/public/javascripts/right.js"))
    get('https://raw.github.com/padrino/padrino-static/master/ujs/right.js', destination_root("/public/javascripts/right-ujs.js"))
  rescue
    copy_file('templates/static/js/right.js',  destination_root("/public/javascripts/right.js"))
    copy_file('templates/static/ujs/right.js', destination_root("/public/javascripts/right-ujs.js"))
  end
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end
