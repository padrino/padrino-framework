MUSTACHE_INIT = <<-MUSTACHE

    require 'mustache/sinatra'
    app.register Mustache::Sinatra
    app.set :layout, 'app/views/layout.rb'
    app.set :mustache, {
      :views => 'app/views/',
      :templates => 'app/templates/'
    }
MUSTACHE

LAYOUT_FILE = <<-LAYOUT
class #{@app_name}
  module Views
    class Layout < Mustache
    end
  end
end
LAYOUT

def setup_renderer
  require_dependencies 'mustache', :version => '>= 0.11.2'
  empty_directory 'app/templates'
  create_file 'app/views/layout.rb', LAYOUT_FILE
  create_file 'app/templates/layout.mustache', '{{{yield}}}'
  initializer :mustache, MUSTACHE_INIT
end
