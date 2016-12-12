require 'minitest/autorun'
require 'minitest/pride'

describe "Padrino" do
  it "should be a metagem that requires subgems" do
    refute defined?(Padrino::Mailer)
    refute defined?(Padrino::Helpers)
    require File.expand_path('../../lib/padrino.rb', __FILE__)
    assert defined?(Padrino::Mailer)
    assert defined?(Padrino::Helpers)
  end
end
