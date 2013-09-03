require File.expand_path('../../helper', __FILE__)
require File.expand_path('../shared', __FILE__)

class DalliTest < BaseTest
  def load_store
    require 'dalli'
    connection = ::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1)
    connection.set('ping','alive')
    Padrino::Cache::Store::Memcache.new(connection)
    false
    rescue LoadError
      true
  end

  before do
    skip if should_skip?
    connection    = ::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1)
    Padrino.cache = Padrino::Cache::Store::Memcache.new(connection)
    Padrino.cache.flush
    @test_key = "val_#{Time.now.to_i}"
  end

  after do
    Padrino.cache.flush
  end

  it_behaves_like :cacheable
end
