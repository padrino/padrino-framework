require 'minitest/autorun'
require 'minitest/spec'

class BaseTest < MiniTest::Spec
  def load_store; true; end

  def should_skip?
    @skip ||= load_store
  end
end

shared_examples_for :cacheable do
  describe 'Cache' do
    
    class Foo
        def bar; "bar"; end
    end

    it "return nil trying to get a value that doesn't exist" do
      Padrino.cache.flush
      assert_equal nil, Padrino.cache.get(@test_key)
    end

    it 'set and get an object w/marshal' do
      Padrino.cache.parser = :marshal
      Padrino.cache.set(@test_key, Foo.new)
      assert_equal "bar", Padrino.cache.get(@test_key).bar
    end

    it 'set and get a nil value' do
      Padrino.cache.set(@test_key, nil)
      assert_equal '', Padrino.cache.get(@test_key).to_s
    end

    it 'set and get a raw value' do
      Padrino.cache.set(@test_key, 'foo')
      assert_equal 'foo', Padrino.cache.get(@test_key)
    end

    it "set a value that expires" do
      init_time = ( Time.now - 20 )
      Time.stub(:now, init_time) { Padrino.cache.set(@test_key, 'test', :expires_in => 1) }
      Time.stub(:now, init_time + 20) { assert_equal nil, Padrino.cache.get(@test_key) }
    end

    it "be able to cache forever" do
      Padrino.cache.set('forever', 'cached', :expires_in => -1)
      2.times { |i| assert_equal 'cached', Padrino.cache.get('forever') }
    end

    it 'delete a value' do
      Padrino.cache.set(@test_key, 'test')
      assert_equal 'test', Padrino.cache.get(@test_key)
      Padrino.cache.delete(@test_key)
      assert_equal nil, Padrino.cache.get(@test_key)
    end
  end
end
