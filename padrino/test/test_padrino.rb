require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Padrino" do
  should "be a metagem that requires subgems" do
    assert_nil defined?(Padrino::Mailer)
    assert_nil defined?(Padrino::Helpers)
    require File.expand_path('../../lib/padrino.rb', __FILE__)
    assert_not_nil defined?(Padrino::Mailer)
    assert_not_nil defined?(Padrino::Helpers)
  end
end
