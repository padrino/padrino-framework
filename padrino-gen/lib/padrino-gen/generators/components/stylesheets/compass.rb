COMPASS_INIT = <<-COMPASS unless defined?(COMPASS_INIT)
    # Enables support for Compass, a stylesheet authoring framework based on SASS.
    # See http://compass-style.org/ for more details.
    # Store Compass/SASS files (by default) within 'app/stylesheets'.
    require 'sass/plugin/rack'

    Compass.configuration do |config|
      config.project_path = Padrino.root
      config.sass_dir = "app/stylesheets"
      config.project_type = :stand_alone
      config.http_path = "/"
      config.css_dir = "public/stylesheets"
      config.images_dir = "public/images"
      config.javascripts_dir = "public/javascripts"
      config.output_style = :compressed
    end

    Compass.configure_sass_plugin!
    Compass.handle_configuration_change!

    app.use Sass::Plugin::Rack
COMPASS

def setup_stylesheet
  require_dependencies 'compass-blueprint'
  initializer :compass, COMPASS_INIT.chomp
  directory "components/stylesheets/compass/", destination_root('/app/stylesheets')
end
