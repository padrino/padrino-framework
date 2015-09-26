SASS_INIT = <<-SASS unless defined?(SASS_INIT)
    # Enables support for SASS template reloading in rack applications.
    # See http://nex-3.com/posts/88-sass-supports-rack for more details.
    # Store SASS files (by default) within 'app/stylesheets'.
    require 'sass/plugin/rack'
    Sass::Plugin.options[:template_location] = Padrino.root("app/stylesheets")
    Sass::Plugin.options[:css_location] = Padrino.root("public/stylesheets")
    app.use Sass::Plugin::Rack
SASS

def setup_stylesheet
  require_dependencies 'sass'
  initializer :sass, SASS_INIT.chomp
  empty_directory destination_root('/app/stylesheets')
end
