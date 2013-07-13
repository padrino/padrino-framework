require File.expand_path('../../helper', __FILE__)
require File.expand_path('../shared', __FILE__)

class MongoTest < BaseTest
  def load_store
    require 'mongo'
    if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
      fail NotImplementedError, "Skipping mongo test for rbx"
    end
    connection = ::Mongo::Connection.new('127.0.0.1', 27017).db('padrino-cache_test')
    Padrino::Cache::Store::Mongo.new(connection)
    false
    rescue LoadError, Mongo::ConnectionFailure, NotImplementedError => e
      true
  end

  before do 
    skip if should_skip?
    connection    = ::Mongo::Connection.new('127.0.0.1', 27017).db('padrino-cache_test')
    config        = {:size => 10, :collection => 'cache'}
    Padrino.cache = Padrino::Cache::Store::Mongo.new(connection, config)
    Padrino.cache.flush
    @test_key = "val_#{Time.now.to_i}"
  end

  after do
    Padrino.cache.flush
  end
  
  it_behaves_like :cacheable

end
