require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestObject
  attr_accessor :id
end

class TestDomHelpers < Test::Unit::TestCase
  include Padrino::Helpers::DomHelpers

  class SecondTestObject
    attr_accessor :id
  end

  context 'for #dom_id method' do
    should "return DOM id based on name of given object" do
      assert_equal dom_id(TestObject.new), "test_object"
      assert_equal dom_id(TestDomHelpers::SecondTestObject.new), "test_dom_helpers_second_test_object"
    end
    should "prepend given prefix to generated id" do
      assert_equal dom_id(TestObject.new, "new"), "new_test_object"
    end
    should "append object #id to generated id if it's not empty" do
      test_obj = TestObject.new
      test_obj.id = 10
      assert_equal dom_id(test_obj), "test_object_10"
    end
  end

  context 'for #dom_class method' do
    should "return DOM class name based on name of given object" do
      assert_equal dom_class(TestObject.new), "test_object"
    end
    should "prepend given prefix to generated class name" do
      assert_equal dom_class(TestObject.new, "new"), "new_test_object"
    end
  end
end