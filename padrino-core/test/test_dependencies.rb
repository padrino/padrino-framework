require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestDependencies < Test::Unit::TestCase
  context 'when we require a dependency that have another dependecy' do

    should 'raise an error without padrino' do
      assert_raise NameError do
        require "fixtures/dependencies/a.rb"
        require "fixtures/dependencies/b.rb"
        require "fixtures/dependencies/c.rb"
      end
    end

    should 'resolve dependency problems' do
      silence_warnings do
        Padrino.require_dependencies(
          Padrino.root("fixtures/dependencies/a.rb"),
          Padrino.root("fixtures/dependencies/b.rb"),
          Padrino.root("fixtures/dependencies/c.rb")
        )
      end
      assert_equal ["B", "A"], A_result
      assert_equal ["C", "B"], B_result
    end
  end

end