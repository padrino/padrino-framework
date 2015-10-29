require File.expand_path(File.dirname(__FILE__) + '/helper')

class MiniTest::Spec
  def assert_query_equal(expected, actual, namespace=nil)
    assert_equal expected.split('&').sort, Padrino::Utils.build_uri_query(actual, namespace).split('&').sort
  end
end

describe 'Padrino::Utils.build_uri_query' do
  it 'should do simple conversion' do
    assert_query_equal 'a=10', :a => 10
  end

  it 'should do cgi escaping' do
    assert_query_equal 'a%3Ab=c+d', 'a:b' => 'c d'
  end

  it 'should expand nested hashes' do
    assert_query_equal 'person%5Blogin%5D=seckar&person%5Bname%5D=Nicholas',
      :person => { :login => 'seckar', :name => 'Nicholas' }
  end

  it 'should expand deeply nested hashes' do
    assert_query_equal 'account%5Bperson%5D%5Bid%5D=20&person%5Bid%5D=10',
      { :account => { :person => { :id => 20 } }, :person => {:id => 10} }
  end

  it 'should accept arrays' do
    assert_query_equal 'person%5Bid%5D%5B%5D=10&person%5Bid%5D%5B%5D=20',
      :person => {:id => [10, 20]}
  end

  it 'should accept empty arrays' do
    assert_query_equal "person%5B%5D=",
      [],
      'person'
  end

  it 'should expand nested hashes' do
    assert_query_equal '',
      {}
    assert_query_equal 'a=1&b%5Bc%5D=3',
      { a: 1, b: { c: 3, d: {} } }
    assert_query_equal '',
      { a: {b: {c: {}}} }
    assert_query_equal 'b%5Bc%5D=false&b%5Be%5D=&b%5Bf%5D=&p=12',
      { p: 12, b: { c: false, e: nil, f: '' } }
    assert_query_equal 'b%5Bc%5D=3&b%5Bf%5D=',
      { b: { c: 3, k: {}, f: '' } }
    assert_query_equal 'b=3',
      {a: [], b: 3}
  end

  it 'should accept namespace for hashes' do
    assert_query_equal "user%5Bname%5D=Nakshay&user%5Bnationality%5D=Indian", 
      { name: 'Nakshay', nationality: 'Indian' },
      'user'
  end
end
