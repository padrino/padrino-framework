require File.expand_path('../../helper', __FILE__)
require File.expand_path('../shared', __FILE__)

class InMemoryStoreTest < BaseTest
  before :each do
    Padrino.cache = Padrino::Cache::Store::Memory.new(50)
    @test_key = "val_#{Time.now.to_i}"
    Padrino.cache.flush
  end
  after(:each)  { Padrino.cache.flush }
  
  it_behaves_like :cacheable

  it "only store 50 entries" do
    51.times { |i| Padrino.cache.set(i.to_s, i.to_s) }
    assert_equal nil, Padrino.cache.get('0')
    assert_equal '1', Padrino.cache.get('1')
  end
end
