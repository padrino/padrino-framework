ENV['RACK_ENV'] = 'test'

require 'padrino-core'

require 'minitest/autorun'
require 'minitest/benchmark'
require 'rack/test'

class Minitest::Benchmark
  def self.bench_range
    [20, 80, 320, 1280]
  end

  def self.io
    $stdout
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
end

describe 'Padrino Core Benchmark' do
  before do
    Padrino.clear!

    paths = (1..100).map{ rand(36**8).to_s(36) }

    mock_app do
      get("/foo") { "okey" }

      paths.each do |p|
        get("/#{p}") { p.to_s }
      end
    end

    get '/'

    @paths = paths
  end

  bench_performance_linear 'calling one path', 0.99 do |n|
    n.times do
      get '/foo'
    end
  end

  bench_performance_linear 'calling 404', 0.99 do |n|
    n.times do
      get "/#{@paths.sample}_not_found"
    end
  end

  bench_performance_linear 'clean sample', 0.99 do |n|
    n.times{ @paths.sample }
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
