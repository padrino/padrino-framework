def setup_script
  copy_file('templates/ujs.js', destination_root('/public/javascripts/ujs.js'), skip: true)
  create_file(destination_root('/public/javascripts/application.js'), '// Put your application scripts here', skip: true)
  # Without padrino-helpers, as in an --api project, the layout has neither helper.
  if padrino_gem?('padrino-helpers')
    say "Add csrf_meta_tags and javascript_include_tag('ujs') to the <head> of your layout, and remove the include tag of any script it replaces.", :yellow
  else
    say 'Add to the <head> of your layout:', :yellow
    say '  <script src="/javascripts/ujs.js"></script>', :yellow
  end
end
