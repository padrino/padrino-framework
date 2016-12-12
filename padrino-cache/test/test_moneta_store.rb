require File.expand_path(File.dirname(__FILE__) + '/helper')

describe 'Padrino::Cache - Moneta store' do
  def setup
    @test_key = "val_#{Time.now.to_i}"
  end

  def teardown
    Padrino.cache.clear
  end

  class Foo
    def bar; "bar"; end
  end

  it "return nil trying to get a value that doesn't exist" do
    Padrino.cache.clear
    assert_nil Padrino.cache[@test_key]
  end

  it 'set and get an object with marshal' do
    Padrino.cache[@test_key] = Foo.new
    assert_equal "bar", Padrino.cache[@test_key].bar
  end

  it 'set and get a nil value' do
    Padrino.cache[@test_key] = nil
    assert_equal '', Padrino.cache[@test_key].to_s
  end

  it 'set and get a raw value' do
    Padrino.cache[@test_key] = 'foo'
    assert_equal 'foo', Padrino.cache[@test_key]
  end

  it "set a value that expires" do
    init_time = ( Time.now - 20 )
    Time.stub(:now, init_time) { Padrino.cache.store(@test_key, 'test', :expires => 1) }
    Time.stub(:now, init_time + 20) { assert_nil Padrino.cache[@test_key] }
  end

  it "be able to cache forever" do
    Padrino.cache.store('forever', 'cached', :expires => false)
    2.times { |i| assert_equal 'cached', Padrino.cache['forever'] }
  end

  it 'delete a value' do
    Padrino.cache[@test_key] = 'test'
    assert_equal 'test', Padrino.cache[@test_key]
    Padrino.cache.delete(@test_key)
    assert_nil Padrino.cache[@test_key]
  end
end
