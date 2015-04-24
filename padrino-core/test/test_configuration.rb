require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "PadrinoConfiguration" do
  it 'should be able to store values' do
    Padrino.config.val1 = 12345
    assert_equal 12345, Padrino.config.val1
  end

  it 'should be able to configure with block' do
    Padrino.configure do |config|
      config.val2 = 54321
    end
    assert_equal 54321, Padrino.config.val2
  end

  it 'should be able to configure with block' do
    Padrino.configure :test do |config|
      config.test1 = 54321
    end
    Padrino.configure :development do |config|
      config.test1 = 12345
    end
    Padrino.configure :test, :development do |config|
      config.both1 = 54321
    end
    assert_equal 54321, Padrino.config.test1
    assert_equal 54321, Padrino.config.both1
  end
end
