require File.expand_path('../helper', __FILE__)

describe 'Named routes' do

  let(:app) { Padrino.new }

  it 'raise an error if path is not defined' do
    assert_raises(ArgumentError){ app.get(:foo){} }
  end

  it 'accept descriptions' do
    skip
    app.desc 'foo'
    app.get('bar'){}
    assert_nil app.routes
  end
end
