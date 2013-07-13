require File.expand_path('../helper', __FILE__)

Shared = File.read File.expand_path('../shared.rb', __FILE__)

begin
  require 'memcached'
  # we're just going to assume memcached is running on the default port
  Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1)).set('ping','alive')
rescue LoadError
  warn "Skipping memcache with memcached library tests"
rescue Memcached::SystemError
  warn "Skipping memcache with memcached server tests"
else
  describe "MemcacheStore" do
    def setup
      Padrino.cache = Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
      Padrino.cache.flush
      @test_key = "val_#{Time.now.to_i}"
    end

    def teardown
      Padrino.cache.flush
    end

    eval Shared
  end
end

begin
  require 'dalli'
  # we're just going to assume memcached is running on the default port
  Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1).set('ping','alive'))

  describe "MemcacheWithDalliStore" do
    def setup
      Padrino.cache = Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
      Padrino.cache.flush
      @test_key = "val_#{Time.now.to_i}"
    end

    def teardown
      Padrino.cache.flush
    end

    eval Shared
  end
rescue LoadError, Dalli::RingError
  warn "Skipping memcache with dalli library tests"
end

begin
  require 'redis'
  Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0).set('ping','alive'))
rescue LoadError
  warn "Skipping redis  with redis library tests"
rescue Redis::CannotConnectError
  warn "Skipping redis with redis server tests"
else
  describe "RedisStore" do
    def setup
      Padrino.cache = Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
      Padrino.cache.flush
      @test_key = "val_#{Time.now.to_i}"
    end

    def teardown
      Padrino.cache.flush
    end

    eval <<-REDIS_TEST
should 'add a value to a list' do
  Padrino.cache.lpush(@test_key, "test")
  assert_equal "test", Padrino.cache.lpop(@test_key)
end
    REDIS_TEST

    eval Shared
  end
end

begin
  require 'mongo'
  fail NotImplementedError, "Skipping mongo test for rbx"  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
  Padrino::Cache::Store::Mongo.new(::Mongo::Connection.new('127.0.0.1', 27017).db('padrino-cache_test'))
rescue LoadError
  warn "Skipping Mongo tests with Mongo library tests"
rescue Mongo::ConnectionFailure
  warn "Skipping Mongo with server tests"
rescue NotImplementedError => e
  warn e.to_s
else
  describe "MongoStore" do
    def setup
      Padrino.cache = Padrino::Cache::Store::Mongo.new(::Mongo::Connection.new('127.0.0.1', 27017).db('padrino-cache_test'), {:size => 10, :collection => 'cache'})
      Padrino.cache.flush
      @test_key = "val_#{Time.now.to_i}"
    end

    def teardown
      Padrino.cache.flush
    end

    eval Shared
  end
end

describe "FileStore" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    FileUtils.mkdir_p(@apptmp)
    Padrino.cache = Padrino::Cache::Store::File.new(@apptmp)
    @test_key = "val_#{Time.now.to_i}"
  end

  def teardown
    Padrino.cache.flush
  end

  eval Shared
end

describe "InMemoryStore" do
  def setup
    Padrino.cache = Padrino::Cache::Store::Memory.new(50)
    @test_key = "val_#{Time.now.to_i}"
  end

  def teardown
    Padrino.cache.flush
  end

  eval Shared

  should "only store 50 entries" do
    51.times { |i| Padrino.cache.set(i.to_s, i.to_s) }
    assert_equal nil, Padrino.cache.get('0')
    assert_equal '1', Padrino.cache.get('1')
  end
end
