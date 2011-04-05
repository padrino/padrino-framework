require File.expand_path(File.dirname(__FILE__) + '/helper')

class Foo
  def bar; "bar"; end
end

COMMON_TESTS = <<-HERE_DOC
should 'set and get an object' do
  Padrino.cache.set('val', Foo.new)
  assert_equal "bar", Padrino.cache.get('val').bar
end

should 'set ang get a nil value' do
  Padrino.cache.set('val', nil)
  assert_equal nil, Padrino.cache.get('val')
end

should 'set and get a raw value' do
  Padrino.cache.set('val', 'foo')
  assert_equal 'foo', Padrino.cache.get('val')
end

should "return nil trying to get a value that doesn't exist" do
  assert_equal nil, Padrino.cache.get('test')
end

should "set a value that expires" do
  Padrino.cache.set('val', 'test', :expires_in => 1)
  assert_equal 'test', Padrino.cache.get('val')
  sleep 2
  assert_equal nil, Padrino.cache.get('val')
end

should 'delete a value' do
  Padrino.cache.set('val', 'test')
  assert_equal 'test', Padrino.cache.get('val')
  Padrino.cache.delete('val')
  assert_equal nil, Padrino.cache.get('val')
end
HERE_DOC

begin
  require 'memcached'
  # we're just going to assume memcached is running on the default port
  Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1)).set('ping','alive')

  class TestMemcacheStore < Test::Unit::TestCase
    def setup
      Padrino.cache = Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
      Padrino.cache.flush
    end

    def teardown
      Padrino.cache.flush
    end

    eval COMMON_TESTS
  end
rescue LoadError
  warn "Skipping memcached with memcached library tests"
end

begin
  require 'dalli'
  # we're just going to assume memcached is running on the default port
  Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1).set('ping','alive'))

  class TestMemcacheWithDalliStore < Test::Unit::TestCase
    def setup
      Padrino.cache = Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
      Padrino.cache.flush
    end

    def teardown
      Padrino.cache.flush
    end

    eval COMMON_TESTS
  end
rescue LoadError
  warn "Skipping memcached with dalli library tests"
end

begin
  require 'redis'
  Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0).set('ping','alive'))
  class TestRedisStore < Test::Unit::TestCase
    def setup
      Padrino.cache = Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
      Padrino.cache.flush
    end

    def teardown
      Padrino.cache.flush
    end

    eval COMMON_TESTS
  end
rescue
  warn "Skipping redis tests"
end

class TestFileStore < Test::Unit::TestCase
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    FileUtils.mkdir_p(@apptmp)
    Padrino.cache = Padrino::Cache::Store::File.new(@apptmp)
  end

  def teardown
    Padrino.cache.flush
  end

  eval COMMON_TESTS
end

class TestInMemoryStore < Test::Unit::TestCase
  def setup
    Padrino.cache = Padrino::Cache::Store::Memory.new(50)
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