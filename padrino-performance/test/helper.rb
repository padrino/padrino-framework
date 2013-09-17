require File.expand_path('../../../load_paths', __FILE__)
require File.join(File.dirname(__FILE__), '..', '..', 'padrino-core', 'test', 'mini_shoulda')

require 'padrino-core'
require 'padrino-performance'
require 'rack'
require 'rack/test'

class MiniTest::Spec
  include Rack::Test::Methods
end

