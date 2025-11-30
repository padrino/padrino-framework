ENV['RACK_ENV'] = 'test'
PADRINO_ROOT = __dir__ unless defined?(PADRINO_ROOT)

require 'minitest/autorun'
require 'minitest/pride'
require 'padrino-support'
require 'padrino-core/logger'
