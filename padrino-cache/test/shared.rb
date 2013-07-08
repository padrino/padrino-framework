class Foo
    def bar; "bar"; end
end

should "return nil trying to get a value that doesn't exist" do
  assert_equal nil, Padrino.cache.get(@test_key)
end

should 'set and get an object w/marshal' do
  Padrino.cache.parser = :marshal
  Padrino.cache.set(@test_key, Foo.new)
  assert_equal "bar", Padrino.cache.get(@test_key).bar
end

should 'set and get a nil value' do
  Padrino.cache.set(@test_key, nil)
  assert_equal '', Padrino.cache.get(@test_key).to_s
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

should "be able to cache forever" do
  Padrino.cache.set('forever', 'cached', :expires_in => -1)
  2.times { |i| assert_equal 'cached', Padrino.cache.get('forever') }
end

should 'delete a value' do
  Padrino.cache.set(@test_key, 'test')
  assert_equal 'test', Padrino.cache.get(@test_key)
  Padrino.cache.delete(@test_key)
  assert_equal nil, Padrino.cache.get(@test_key)
end
