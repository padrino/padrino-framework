SLIM_INIT = (<<-SLIM).gsub(/^/, '    ')
# Sets slim to use the default output buffer to fix concat and capture in Padrino
Slim::Engine.set_default_options :buffer => '@_out_buf', :auto_escape => false
SLIM

def setup_renderer
  require_dependencies 'slim', :version => "~> 0.9.2"
  initializer :slim, SLIM_INIT.chomp
end