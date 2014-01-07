require File.expand_path('../helper', __FILE__)

describe "Padrino::Auth" do

  before do
  end

  after do
  end

  should 'have all the constants required' do
    assert Padrino::Login
    assert Padrino::Access
    assert Padrino::Permissions
  end
end
