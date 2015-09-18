ENV['RACK_ENV'] = 'test'

require 'padrino-core'

require 'minitest/autorun'
require 'minitest/benchmark'
require 'rack/test'

class Padrino::BenchSpec < Minitest::BenchSpec
  def self.bench_range
    [20, 80, 320, 1280]
  end

  def result_code
    ''
  end

  include Rack::Test::Methods

  def mock_app(base=Padrino::Application, &block)
    @app = Sinatra.new(base, &block)
  end

  def app
    Rack::Lint.new(@app)
  end

  def self.bench_performance_any(name, &work)
    bench name do
      validation = proc do |range, times|
        assert true
      end
      assert_performance(validation, &work)
    end
  end

  def self.run(*)
    puts self if self.superclass == Padrino::BenchSpec
    super
  end

  Minitest::Spec.register_spec_type(/^Padrino .* Performance$/, Padrino::BenchSpec)
end

describe 'Padrino Routing Performance' do
  before do
    Padrino.clear!

    @paths = paths = (1..100).map{ rand(36**8).to_s(36) }

    mock_app do
      get("/foo") { "okey" }

      paths.each do |p|
        get("/#{p}") { p.to_s }
      end
    end

    get '/'
  end

  bench_performance_linear 'calling 404', 0.99 do |n|
    n.times do
      get "/#{@paths.sample}_not_found"
    end
  end

  bench_performance_linear 'calling one path', 0.99 do |n|
    n.times do
      get '/foo'
    end
  end

  bench_performance_linear 'calling sample', 0.99 do |n|
    n.times do
      get "/#{@paths.sample}"
    end
  end

  bench_performance_linear 'calling params', 0.99 do |n|
    n.times do
      get "/foo?foo=bar&zoo=#{@paths.sample}"
    end
  end

  bench_performance_linear 'sample and params', 0.99 do |n|
    n.times do
      get "/#{@paths.sample}?foo=bar&zoo=#{@paths.sample}"
    end
  end
end

describe 'Padrino Mounter Performance' do
  class TestApp < Padrino::Application
    get '/' do
      'OK'
    end
  end

  before do
    Padrino.clear!

    @paths = paths = (1..100).map{ rand(36**8).to_s(36) }

    test_app = TestApp.dup

    paths.each do |p|
      Padrino.mount(TestApp).to("/#{p}")
    end
  end

  bench_performance_any 'mounted sample' do |n|
    request = Rack::MockRequest.new(Padrino.application)
    n.times do
      response = request.get("/#{@paths.sample}")
      assert_equal 200, response.status
    end
  end
end
