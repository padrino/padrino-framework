require 'optparse'
require File.expand_path('../../padrino-core', __FILE__)

options = {}

OptionParser.new do |opt|
  opt.banner  = 'padrino options:'
  opt.version = Padrino.version
  opt.on('-h')        { puts opt; exit(0) }
  opt.on('-p port')   { |v| options[:Port]   = v.to_i }
  opt.on('-o host')   { |v| options[:Host]   = v }
  opt.on('-s server') { |v| options[:server] = v }
  opt.on('-e env') do |v|
    defined?(PADRINO_ENV) ? PADRINO_ENV.replace(v) : PADRINO_ENV=v
  end
  opt.parse!(ARGV.dup)
end

at_exit do
  next if $! # exit if there was an error
  Padrino.run!(options) unless Padrino.loaded?
end
