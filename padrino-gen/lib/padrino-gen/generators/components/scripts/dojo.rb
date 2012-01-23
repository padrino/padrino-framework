def setup_script
  begin
    get('https://raw.github.com/padrino/padrino-static/master/js/dojo.js',  destination_root("/public/javascripts/dojo.js"))
    get('https://raw.github.com/padrino/padrino-static/master/ujs/dojo.js', destination_root("/public/javascripts/dojo-ujs.js"))
  rescue
    copy_file('templates/static/js/dojo.js',  destination_root("/public/javascripts/dojo.js"))
    copy_file('templates/static/ujs/dojo.js', destination_root("/public/javascripts/dojo-ujs.js"))
  end
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end
