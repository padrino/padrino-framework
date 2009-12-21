require File.dirname(__FILE__) + '/helper'

class ParsingTest < Test::Unit::TestCase

  should "Parse Nested Childs" do
    config = ExtJs::Config.load <<-YAML
      foo:
        bar:
          name: Fred
      bar: %foo/bar
    YAML
    assert_equal config["foo"]["bar"], config["bar"]
  end

  should "Parse JS and Nested JS" do
    config = ExtJs::Config.load <<-YAML
      nested:
        fn: !js function(){ alert('nested fn') }
      fn: !js function(){ alert('fn') }
      array: [!js function(){ alert('array') }]
      test_one: %fn
      test_two: %nested/fn
      test_three:
        no_nested: %fn
        nested: %nested/fn
    YAML
    
    assert_kind_of ExtJs::Variable, config["test_one"]
    assert_kind_of ExtJs::Variable, config["test_one"]
    assert_kind_of ExtJs::Variable, config["test_three"]["no_nested"]
    assert_kind_of ExtJs::Variable, config["test_three"]["nested"]
    assert_kind_of ExtJs::Variable, config["array"].first
    
    assert_equal "function(){ alert('fn') }", config["test_one"]
    assert_equal "function(){ alert('nested fn') }", config["test_two"]
    assert_equal "function(){ alert('fn') }", config["test_three"]["no_nested"]
    assert_equal "function(){ alert('nested fn') }", config["test_three"]["nested"]
    assert_equal "function(){ alert('array') }", config["array"].first
  end

  should "Parse a multinested YAML" do
    config = ExtJs::Config.load <<-YAML
      buttons:
        - id: add
          text: Add Product
        - id: delete
          text: Delete Product
      default:
        tbar:
          buttons: %buttons
      grid:
        tbar: %default/tbar
    YAML
    assert_equal config["default"]["tbar"], config["grid"]["tbar"]
    assert_equal config["buttons"], config["default"]["tbar"]["buttons"]
    assert_equal config["buttons"], config["grid"]["tbar"]["buttons"]
    assert_equal ["add", "delete"], config["grid"]["tbar"]["buttons"].collect { |b| b["id"] }
    
  end

  should "Parse array and hashes" do
    config = ExtJs::Config.load <<-YAML
      a: a
      b: b
      c: c
      array: [%a, %b, %c]
      hash: { a: %a, b: %b, c: %c }
    YAML
    assert_equal ["a", "b", "c"], config["array"]
    assert_equal({"a" => "a", "b" => "b", "c" => "c"}, config["hash"])
  end

  should "Merge config" do
    config = ExtJs::Config.load <<-YAML
      default:
        grid:
          editable: false
          template: standard
          cls: default
        tbar:
          buttons:
            - text: Add
              cls: x-btn-text-icon add
            - text: Delete
              disabled: true
              cls: x-btn-text-icon print
              handler: !js delete

      grid:
        <<: %default/grid
        editable: true
        title: Elenco <%= @title %>
        basepath: /backend/orders
        sm: checkbox
        template: custom
        tbar:
          buttons:
            - <<: %default/tbar/buttons
            - text: Test
    YAML
    assert_equal true, config["grid"]["editable"]
    assert_equal "default", config["grid"]["cls"]
    assert_equal "custom", config["grid"]["template"]
    assert_equal ["Add", "Delete", "Test"], config["grid"]["tbar"]["buttons"].collect { |b| b["text"] }
  end
  
  should "Merge a complex config" do
    config = ExtJs::Config.load <<-YAML
      default:
        grid:
          editable: false
          template: standard
          cls: default
          tbar:
            buttons:
              - text: Add
                cls: x-btn-text-icon add
              - text: Delete
                disabled: true
                cls: x-btn-text-icon print
                handler: !js delete

      grid:
        <<: %default/grid
        editable: true
        title: Elenco <%= @title %>
        basepath: /backend/orders
        sm: checkbox
        template: custom
    YAML
    assert_equal true, config["grid"]["editable"]
    assert_equal "default", config["grid"]["cls"]
    assert_equal "custom", config["grid"]["template"]
    assert_equal ["Add", "Delete"], config["grid"]["tbar"]["buttons"].collect { |b| b["text"] }
  end
end