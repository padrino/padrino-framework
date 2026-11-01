def setup_script
  copy_file('templates/ujs.js', destination_root('/public/javascripts/ujs.js'), skip: true)
  create_file(destination_root('/public/javascripts/application.js'), '// Put your application scripts here', skip: true)
  say "Add csrf_meta_tags and javascript_include_tag('ujs') to the <head> of your layout, and remove the include tag of any script it replaces.", :yellow
end
