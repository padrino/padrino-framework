def setup_script
  begin
    get('https://raw.github.com/padrino/padrino-static/master/js/ext.js',  destination_root("/public/javascripts/ext.js"))
    get('https://raw.github.com/padrino/padrino-static/master/ujs/ext.js', destination_root("/public/javascripts/ext-ujs.js"))
  rescue
    copy_file('templates/static/js/ext.js',  destination_root("/public/javascripts/ext.js"))
    copy_file('templates/static/ujs/ext.js', destination_root("/public/javascripts/ext-ujs.js"))
  end
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end
