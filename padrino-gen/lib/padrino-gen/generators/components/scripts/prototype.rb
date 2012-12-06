def setup_script
  begin
    get('https://raw.github.com/padrino/padrino-static/master/js/protopak.js',   destination_root("/public/javascripts/protopak.js"))
    get('https://raw.github.com/padrino/padrino-static/master/js/lowpro.js',     destination_root("/public/javascripts/lowpro.js"))
    get('https://raw.github.com/padrino/padrino-static/master/ujs/prototype.js', destination_root("/public/javascripts/prototype-ujs.js"))
  rescue
    copy_file('templates/static/js/protopak.js',   destination_root("/public/javascripts/protopak.js"))
    copy_file('templates/static/js/lowpro.js',     destination_root("/public/javascripts/lowpro.js"))
    copy_file('templates/static/ujs/prototype.js', destination_root("/public/javascripts/prototype-ujs.js"))
  end
  create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
end
