require 'minitest/autorun'
require 'minitest/pride'

describe "Padrino" do
  it "should be a metagem that requires subgems" do
    assert_nil defined?(Padrino::Mailer)
    assert_nil defined?(Padrino::Helpers)
    require File.expand_path('../../lib/padrino.rb', __FILE__)
    refute_nil defined?(Padrino::Mailer)
    refute_nil defined?(Padrino::Helpers)
  end
end
