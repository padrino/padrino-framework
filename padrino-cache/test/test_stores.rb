require File.expand_path(File.dirname(__FILE__) + '/store_helper')

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

class TestMemcacheStore < Test::Unit::TestCase
  def setup
    `memcached -p60123 -U60123 -d`
    @cache = Padrino::Cache::Store::Memcache.new('127.0.0.1:60123')
  end

  def teardown
    `killall memcached`
  end
  
  eval COMMON_TESTS
end

class TestFileStore < Test::Unit::TestCase
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    FileUtils.mkdir_p(@apptmp)
    @cache = Padrino::Cache::Store::File.new(@apptmp)
  end

  def teardown
    FileUtils.rm_rf(@apptmp)
  end
  
  eval COMMON_TESTS
end

class TestInMemoryStore < Test::Unit::TestCase
  def setup
    @cache = Padrino::Cache::Store::Memory.new
  end

  def teardown
  end
  
  eval COMMON_TESTS
end