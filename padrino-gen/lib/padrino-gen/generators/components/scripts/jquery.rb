def setup_script
  begin
    get('https://raw.github.com/padrino/padrino-static/master/js/jquery.js',  destination_root("/public/javascripts/jquery.js"))
    get('https://raw.github.com/padrino/padrino-static/master/ujs/jquery.js', destination_root("/public/javascripts/jquery-ujs.js"))
  rescue
    copy_file('templates/static/js/jquery.js',  destination_root("/public/javascripts/jquery.js"))
    copy_file('templates/static/ujs/jquery.js', destination_root("/public/javascripts/jquery-ujs.js"))
  end
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end
