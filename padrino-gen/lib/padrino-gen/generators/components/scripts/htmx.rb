HTMX_CSRF = <<~JS unless defined?(HTMX_CSRF)
  // Same-origin htmx requests that change state are sent along with the token from csrf_meta_tags.
  document.addEventListener('htmx:configRequest', function(event) {
    var token = document.querySelector('meta[name="csrf-token"]');
    var verb = event.detail.verb;
    var sameOrigin = new URL(event.detail.path, document.baseURI).origin === window.location.origin;
    if (token && sameOrigin && verb !== 'get') event.detail.headers['X-CSRF-Token'] = token.content;
  });
JS

def setup_script
  # htmx.org 2.0.11 dist/htmx.min.js from npm, vendored so that generating needs no network.
  copy_file('templates/htmx/htmx.min.js', destination_root('/public/javascripts/htmx.js'), skip: true)
  # A file of its own: a project switching from another script keeps the application.js it has.
  create_file(destination_root('/public/javascripts/htmx-csrf.js'), HTMX_CSRF, skip: true)
  create_file(destination_root('/public/javascripts/application.js'), '// Put your application scripts here', skip: true)
  # Without padrino-helpers, as in an --api project, the layout has no helpers and the app no CSRF protection.
  unless padrino_gem?('padrino-helpers')
    say 'Add to the <head> of your layout:', :yellow
    say '  <script src="/javascripts/htmx.js"></script>', :yellow
    return
  end
  renderer = layout_renderer
  lines = ['csrf_meta_tags', "javascript_include_tag 'htmx', 'htmx-csrf', 'application'"]
  lines = lines.map { |line| renderer == 'erb' ? "<%= #{line} %>" : "= #{line}" }
  say "Add to the <head> of your layout (views/layouts/application.#{renderer}), so htmx requests pass CSRF protection:", :yellow
  say lines.map { |line| "  #{line}" }.join("\n"), :yellow
end
