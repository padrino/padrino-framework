require File.expand_path('../../../load_paths', __FILE__)

require 'minitest/autorun'
require 'minitest/pride'
require 'padrino-core'
require 'padrino-performance'
require 'rack'
require 'rack/test'

class MiniTest::Spec
  include Rack::Test::Methods
end
