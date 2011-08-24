COMPASS_INIT = (<<-COMPASS).gsub(/^ {10}/, '') unless defined?(COMPASS_INIT)
# Enables support for Compass, a stylesheet authoring framework based on SASS.
# See http://compass-style.org/ for more details.
# Store Compass/SASS files (by default) within 'app/stylesheets'

module CompassInitializer
  def self.registered(app)
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
  end
end
COMPASS

COMPASS_REGISTER = (<<-COMPASSR).gsub(/^ {10}/, '') unless defined?(COMPASS_REGISTER)
  register CompassInitializer\n
COMPASSR

def setup_stylesheet
  require_dependencies 'compass'
  create_file destination_root('/lib/compass_plugin.rb'), COMPASS_INIT
  inject_into_file destination_root('/app/app.rb'), COMPASS_REGISTER, :after => "register Padrino::Helpers\n"

  directory "components/stylesheets/compass/", destination_root('/app/stylesheets')
end
