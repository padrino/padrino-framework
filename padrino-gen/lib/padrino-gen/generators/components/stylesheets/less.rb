LESS_INIT = (<<-LESS).gsub(/^ {6}/, '')
# Enables support for Less template reloading for rack.
# Store Less files by default within 'app/stylesheets/'
# See http://github.com/kelredd/rack-less for more details.
require 'rack/less'
# optional - use as necessary
Rack::Less.configure do |config|
  config.compress = true
  # other configs ...
end
app.use Rack::Less,
:root      => app.root,
:source    => 'stylesheets/',
:public    => 'public/',
:hosted_at => '/stylesheets'
LESS

def setup_stylesheet
  require_dependencies 'rack-less'
  initializer :less, LESS_INIT
  empty_directory destination_root('/app/stylesheets')
end
