require File.expand_path(File.dirname(__FILE__) + '/helper')

class Foo
  def bar; "bar"; end
end

COMMON_TESTS = <<-HERE_DOC
should "return nil trying to get a value that doesn't exist" do
  assert_equal nil, Padrino.cache.get(@test_key)
end

should 'set and get an object' do
  Padrino.cache.set(@test_key, Foo.new)
  assert_equal "bar", Padrino.cache.get(@test_key).bar
end

should 'set and get a nil value' do
  Padrino.cache.set(@test_key, nil)
  assert_equal nil, Padrino.cache.get(@test_key)
end

should 'set and get a raw value' do
  Padrino.cache.set(@test_key, 'foo')
  assert_equal 'foo', Padrino.cache.get(@test_key)
end

should "set a value that expires" do
  Padrino.cache.set(@test_key, 'test', :expires_in => 1)
  # assert_equal 'test', Padrino.cache.get(@test_key) # Fails on race condition
  sleep 2
  assert_equal nil, Padrino.cache.get(@test_key)
end

should 'delete a value' do
  Padrino.cache.set(@test_key, 'test')
  assert_equal 'test', Padrino.cache.get(@test_key)
  Padrino.cache.delete(@test_key)
  assert_equal nil, Padrino.cache.get(@test_key)
end
HERE_DOC

begin
  require 'memcache'
  # we're just going to assume memcached is running on the default port
  Padrino::Cache::Store::Memcache.new(::MemCache.new('127.0.0.1:11211', :exception_retry_limit => 1)).set('ping','alive')

  describe "MemcacheStore" do
    def setup
      Padrino.cache = Padrino::Cache::Store::Memcache.new(::MemCache.new('127.0.0.1:11211', :exception_retry_limit => 1))
      Padrino.cache.flush
    end

    def teardown
      Padrino.cache.flush
    end

    eval COMMON_TESTS
  end
rescue LoadError
  warn "Skipping memcache with memcached library tests"
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

    eval COMMON_TESTS
  end
rescue LoadError
  warn "Skipping memcache with dalli library tests"
end

begin
  require 'redis'
  Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0).set('ping','alive'))
  describe "RedisStore" do
    def setup
      Padrino.cache = Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
      Padrino.cache.flush
      @test_key = "val_#{Time.now.to_i}"
    end

    def teardown
      Padrino.cache.flush
    end

    eval COMMON_TESTS
  end
rescue LoadError
  warn "Skipping redis tests"
end

begin
  require 'mongo'
  Padrino::Cache::Store::Mongo.new(::Mongo::Connection.new('127.0.0.1', 27017).db('padrino-cache_test'))
  describe "MongoStore" do
    def setup
      Padrino.cache = Padrino::Cache::Store::Mongo.new(::Mongo::Connection.new('127.0.0.1', 27017).db('padrino-cache_test'), {:size => 10, :collection => 'cache'})
      Padrino.cache.flush
      @test_key = "val_#{Time.now.to_i}"
    end

    def teardown
      Padrino.cache.flush
    end

    eval COMMON_TESTS
  end
rescue LoadError
  warn "Skipping Mongo tests"
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

  eval COMMON_TESTS
end

describe "InMemoryStore" do
  def setup
    Padrino.cache = Padrino::Cache::Store::Memory.new(50)
    @test_key = "val_#{Time.now.to_i}"
  end

  def teardown
    Padrino.cache.flush
  end

  eval COMMON_TESTS

  should "only store 50 entries" do
    51.times { |i| Padrino.cache.set(i.to_s, i.to_s) }
    assert_equal nil, Padrino.cache.get('0')
    assert_equal '1', Padrino.cache.get('1')
  end
end
