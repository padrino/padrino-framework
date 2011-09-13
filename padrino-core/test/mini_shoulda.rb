require 'minitest/spec'
require 'minitest/autorun'
require 'mocha' # Load mocha after minitest

begin
  require 'ruby-debug'
rescue LoadError; end

class MiniTest::Spec
  class << self
    alias :setup :before unless defined?(Rails)
    alias :teardown :after unless defined?(Rails)
    alias :should :it
    alias :context :describe
    def should_eventually(desc)
      it("should eventually #{desc}") { skip("Should eventually #{desc}") }
    end
  end
  alias :assert_no_match  :refute_match
  alias :assert_not_nil   :refute_nil
  alias :assert_not_equal :refute_equal
end
