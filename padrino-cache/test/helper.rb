ENV['RACK_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined?(PADRINO_ROOT)

require File.join(File.dirname(__FILE__), '..', '..', 'padrino-core', 'test', 'helper')
require 'padrino-cache'
