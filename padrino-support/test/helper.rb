ENV['RACK_ENV'] = 'test'
PADRINO_ROOT = __dir__ unless defined?(PADRINO_ROOT)

require 'minitest/autorun'
begin
  require 'minitest/mock'
rescue LoadError
  # minitest/mock is built-in for older minitest versions
end
require 'minitest/pride'
require 'padrino-support'
require 'padrino-core/logger'
