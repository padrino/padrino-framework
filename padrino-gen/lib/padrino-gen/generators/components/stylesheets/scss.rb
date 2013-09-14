SCSS_INIT = <<-SCSS unless defined?(SCSS_INIT)
    # Enables support for SCSS template reloading in rack applications.
    # See http://nex-3.com/posts/88-sass-supports-rack for more details.
    # Store SCSS files (by default) within 'app/stylesheets'.
    require 'sass/plugin/rack'
    Sass::Plugin.options[:syntax] = :scss
    Sass::Plugin.options[:template_location] = Padrino.root("app/stylesheets")
    Sass::Plugin.options[:css_location] = Padrino.root("public/stylesheets")
    app.use Sass::Plugin::Rack
SCSS

def setup_stylesheet
  require_dependencies 'sass'
  initializer :scss, SCSS_INIT.chomp
  empty_directory destination_root('/app/stylesheets')
end
