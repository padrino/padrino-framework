require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Padrino::Helpers" do
  it 'should allow including without registering' do
    class Foo
      include Padrino::Helpers
    end
    assert_equal '<div>bar</div>', Foo.new.content_tag(:div, 'bar')
  end
end
