require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestDependencies < Test::Unit::TestCase
  context 'when we require a dependency that have another dependency' do

    should 'resolve dependency problems' do
      silence_warnings do
        Padrino.require_dependencies(
          Padrino.root("fixtures/dependencies/a.rb"),
          Padrino.root("fixtures/dependencies/b.rb"),
          Padrino.root("fixtures/dependencies/c.rb")
        )
      end
      assert_equal ["B", "C"], A_result
      assert_equal "C", B_result
      assert_equal 1, Foo::Bar
    end
  end
end