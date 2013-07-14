require File.expand_path('../../helper', __FILE__)
require File.expand_path('../shared', __FILE__)

class MemcachedTest < BaseTest
  def load_store
    require 'memcached'
    connection = ::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1)
    Padrino::Cache::Store::Memcache.new(connection).set('ping','alive')
    @test_key = "val_#{Time.now.to_i}"
    false
    rescue LoadError
      true
    rescue Memcached::SystemError
      true
  end

  before do
    Padrino.cache.flush
  end
  
  it_behaves_like :cacheable
end
