require_relative 'helper'
require 'tmpdir'

describe 'Padrino::Cache - Moneta store' do
  def setup
    @test_key = "val_#{Time.now.to_i}"
  end

  def teardown
    Padrino.cache.clear
  end

  class Foo
    def bar; 'bar'; end
  end

  it "return nil trying to get a value that doesn't exist" do
    Padrino.cache.clear
    assert_nil Padrino.cache[@test_key]
  end

  it 'set and get an object with marshal' do
    Padrino.cache[@test_key] = Foo.new
    assert_equal 'bar', Padrino.cache[@test_key].bar
  end

  it 'set and get a nil value' do
    Padrino.cache[@test_key] = nil
    assert_equal '', Padrino.cache[@test_key].to_s
  end

  it 'set and get a raw value' do
    Padrino.cache[@test_key] = 'foo'
    assert_equal 'foo', Padrino.cache[@test_key]
  end

  it 'set a value that expires' do
    init_time = Time.now - 20
    Time.stub(:now, init_time) { Padrino.cache.store(@test_key, 'test', expires: 1) }
    Time.stub(:now, init_time + 20) { assert_nil Padrino.cache[@test_key] }
  end

  it 'be able to cache forever' do
    Padrino.cache.store('forever', 'cached', expires: false)
    2.times { assert_equal 'cached', Padrino.cache['forever'] }
  end

  it 'delete a value' do
    Padrino.cache[@test_key] = 'test'
    assert_equal 'test', Padrino.cache[@test_key]
    Padrino.cache.delete(@test_key)
    assert_nil Padrino.cache[@test_key]
  end
end

describe 'Padrino::Cache - thread safety' do
  # Holds the store's lock (if it has one) inside each_key while another thread writes,
  # and returns whether that write had to wait for the lock.
  def write_waits_for_lock?(store)
    store.clear
    store['held'] = 'x'
    inside = Queue.new
    release = Queue.new
    holder = Thread.new { store.each_key { inside << true; release.pop } }
    inside.pop
    writer = Thread.new { store['other'] = 'y' }
    waited = writer.join(0.2).nil?
    release << true
    [holder, writer].each(&:join)
    assert_equal 'y', store['other']
    waited
  ensure
    release&.push(true)
  end

  it 'locks the default store' do
    assert write_waits_for_lock?(Padrino.cache)
  ensure
    Padrino.cache.clear
  end

  it 'locks the in-memory stores' do
    assert write_waits_for_lock?(Padrino::Cache.new(:LRUHash))
    assert write_waits_for_lock?(Padrino::Cache.new(:Memory))
  end

  it 'keeps an explicit threadsafe option' do
    refute write_waits_for_lock?(Padrino::Cache.new(:LRUHash, threadsafe: false))
    Dir.mktmpdir do |dir|
      assert write_waits_for_lock?(Padrino::Cache.new(:File, dir: dir, threadsafe: true))
    end
  end

  it 'leaves other stores unlocked' do
    Dir.mktmpdir do |dir|
      refute write_waits_for_lock?(Padrino::Cache.new(:File, dir: dir))
    end
  end
end
