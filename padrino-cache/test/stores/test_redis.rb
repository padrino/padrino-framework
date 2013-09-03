require File.expand_path('../../helper', __FILE__)
require File.expand_path('../shared', __FILE__)

class RedisTest < BaseTest

  def load_store
    require 'redis'
    store_config = {:host => '127.0.0.1', 
                    :port => 6379,
                    :db   => 0}
    Padrino::Cache::Store::Redis.new(::Redis.new(store_config).set('ping','alive'))
    false
    rescue LoadError, Redis::CannotConnectError
      true
  end

  before do
    skip if should_skip?
    require 'redis' unless defined?(Redis)
    Padrino.cache = Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
    Padrino.cache.flush
    @test_key = "val_#{Time.now.to_i}"
  end
  
  after do
    Padrino.cache.flush
  end

  it_behaves_like :cacheable
end
