ENV['RACK_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined?(PADRINO_ROOT)

require File.expand_path('../../../padrino-core/test/helper', __FILE__)
require 'padrino-cache'
