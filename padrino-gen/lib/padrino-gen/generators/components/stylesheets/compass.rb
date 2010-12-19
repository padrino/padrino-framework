COMPASS_INIT = (<<-COMPASS).gsub(/^ {10}/, '') unless defined?(COMPASS_INIT)
# Enables support for Compass, a stylesheet authoring framework based on SASS.
# See http://compass-style.org/ for more details.
# Store Compass/SASS files (by default) within 'app/stylesheets'

module CompassInitializer
  def self.registered(app)
    require 'sass/plugin/rack'
    Compass.add_project_configuration 'config/compass.config'
    Compass.configure_sass_plugin!
    Compass.handle_configuration_change!
    app.use Sass::Plugin::Rack
  end
end
COMPASS

COMPASS_REGISTER = (<<-COMPASSR).gsub(/^ {10}/, '') unless defined?(COMPASS_REGISTER)
  register CompassInitializer\n
COMPASSR

COMPASS_CONFIGURATION = (<<-COMPASSC).gsub(/^ {10}/, '') unless defined?(COMPASS_CONFIGURATION)
project_path = "."
project_type = :stand_alone
http_path = "/"
sass_dir = "app/stylesheets"
css_dir = "public/stylesheets"
http_stylesheets_path = "/stylesheets"
images_dir = "public/images"
http_images_path = "/images"
javascripts_dir = "public/javascripts"
http_javascripts_path = "/javascripts"
output_style = :compressed
relative_assets = true
COMPASSC

COMPASS_REGISTER = (<<-COMPASSR).gsub(/^ {10}/, '') unless defined?(COMPASS_REGISTER)
  register CompassInitializer\n
COMPASSR

def setup_stylesheet
  require_dependencies 'compass'
  create_file destination_root('/lib/compass_plugin.rb'), COMPASS_INIT
  inject_into_file destination_root('/app/app.rb'), COMPASS_REGISTER, :after => "register Padrino::Helpers\n"
  create_file destination_root('/config/compass.config'), COMPASS_CONFIGURATION
  directory "components/stylesheets/compass/", destination_root('/app/stylesheets')
end