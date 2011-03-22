require File.expand_path(File.dirname(__FILE__) + '/helper')

COMMON_TESTS = <<-HERE_DOC
should 'set and get a value' do
  @cache.set('val', 'test')
  assert_equal 'test', @cache.get('val')
end

should "return nil trying to get a value that doesn't exist" do
  assert_equal nil, @cache.get('test')
end

should "set a value that expires" do
  @cache.set('val', 'test', :expires_in => 1)
  assert_equal 'test', @cache.get('val')
  sleep 2
  assert_equal nil, @cache.get('val')
end

should 'delete a value' do
  @cache.set('val', 'test')
  assert_equal 'test', @cache.get('val')
  @cache.delete('val')
  assert_equal nil, @cache.get('val')
end
HERE_DOC

begin
  require 'memcached'
  # we're just going to assume memcached is running on the default port
  Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1)).set('ping','alive')

  class TestMemcacheStore < Test::Unit::TestCase
    def setup
      @cache = Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
      @cache.flush
    end

    def teardown
      @cache.flush
    end

    eval COMMON_TESTS
  end
rescue LoadError
  warn "Skipping memcached with memcached library tests"
end

begin
  require 'dalli'
  # we're just going to assume memcached is running on the default port
  Padrino::Cache::Store::Memcache.new ::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1).set('ping','alive')

  class TestMemcacheWithDalliStore < Test::Unit::TestCase
    def setup
      @cache = Padrino::Cache::Store::Memcache.new ::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1)
      @cache.flush
    end

    def teardown
      @cache.flush
    end

    eval COMMON_TESTS
  end
rescue LoadError
  warn "Skipping memcached with dalli library tests"
end

begin
  require 'redis'
  Padrino::Cache::Store::Redis.new ::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0).set('ping','alive')
  class TestRedisStore < Test::Unit::TestCase
    def setup
      @cache = Padrino::Cache::Store::Redis.new ::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0)
      @cache.flush
    end

    def teardown
      @cache.flush
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
    @cache = Padrino::Cache::Store::File.new(@apptmp)
  end

  def teardown
    @cache.flush
  end

  eval COMMON_TESTS
end

class TestInMemoryStore < Test::Unit::TestCase
  def setup
    @cache = Padrino::Cache::Store::Memory.new(50)
  end

  def teardown
    @cache.flush
  end

  eval COMMON_TESTS

  should "only store 50 entries" do
    51.times { |i| @cache.set(i.to_s, i.to_s) }
    assert_equal nil, @cache.get('0')
    assert_equal '1', @cache.get('1')
  end
end