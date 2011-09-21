require 'optparse'
require File.expand_path('../version.rb', __FILE__)

options = {}

OptionParser.new do |opt|
  opt.version = Padrino.version
  opt.summary_width = 15
  opt.on('-h', '--help', '# Show this help.') { puts opt; exit }
  opt.on('-p port', '# Set the web server port') { |v| options[:Port]   = v.to_i }
  opt.on('-o host', '# Bind webserver to the given host') { |v| options[:Host]   = v }
  opt.on('-s server', '# Web server handler i.e. thin') { |v| options[:server] = v }
  opt.on('-e env', '# Set the environment') { |v| PADRINO_ENV = v }
  opt.parse!(ARGV.dup)
end

at_exit do
  next if $! # exit if there was an error
  # Auto Mount first detected Padrino::Application subclass to /
  if Padrino.mounted_apps.empty? && !Padrino::Application.descendants.empty?
    Padrino.mount(Padrino::Application.descendants[0]).to("/")
  end
  # Start the webserver
  Padrino.run!(options) unless Padrino.loaded?
end

require File.expand_path('../../padrino-core.rb', __FILE__)
