require File.expand_path("#{File.dirname(__FILE__)}/helper")

describe 'PadrinoConfiguration' do
  it 'should be able to store values' do
    Padrino.config.val1 = 12_345
    assert_equal 12_345, Padrino.config.val1
  end

  it 'should be able to configure with block' do
    Padrino.configure do |config|
      config.val2 = 54_321
    end
    assert_equal 54_321, Padrino.config.val2
  end

  it 'should be able to configure with block' do
    Padrino.configure :test do |config|
      config.test1 = 54_321
    end
    Padrino.configure :development do |config|
      config.test1 = 12_345
    end
    Padrino.configure :test, :development do |config|
      config.both1 = 54_321
    end
    assert_equal 54_321, Padrino.config.test1
    assert_equal 54_321, Padrino.config.both1
  end
end
