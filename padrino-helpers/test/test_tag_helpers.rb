require_relative 'helper'
require_relative 'fixtures/markup_app/app'

describe 'TagHelpers' do
  def app
    MarkupDemo
  end

  describe 'for #tag method' do
    it 'should support tags with no content no attributes' do
      assert_html_has_tag(tag(:br), :br)
    end

    it 'should support tags with no content with attributes' do
      actual_html = tag(:br, style: 'clear:both', class: 'yellow')
      assert_html_has_tag(actual_html, :br, class: 'yellow', style: 'clear:both')
    end

    it 'should support selected attribute by using "selected" if true' do
      actual_html = tag(:option, selected: true)
      # fix nokogiri 1.6.8 on jRuby
      actual_html = content_tag(:select, actual_html)
      assert_html_has_tag(actual_html, 'option', selected: 'selected')
    end

    it 'should support data attributes' do
      actual_html = tag(:a, data: { remote: true, method: 'post' })
      assert_html_has_tag(actual_html, :a, 'data-remote' => 'true', 'data-method' => 'post')
    end

    it 'should support nested attributes' do
      actual_html = tag(:div, data: { dojo: { type: 'dijit.form.TextBox', props: 'readOnly: true' } })
      assert_html_has_tag(actual_html, :div, 'data-dojo-type' => 'dijit.form.TextBox', 'data-dojo-props' => 'readOnly: true')
    end

    it 'should support open tags' do
      actual_html = tag(:p, { class: 'demo' }, true)
      assert_equal '<p class="demo">', actual_html
    end

    it 'should escape html' do
      actual_html = tag(:br, class: 'Example <foo> & "bar"')
      assert_equal '<br class="Example &lt;foo&gt; &amp; &quot;bar&quot;" />', actual_html
    end

    it 'should allow array as attributes' do
      actual_html = tag(:p, class: %i[foo bar])
      assert_html_has_tag(actual_html, 'p.foo.bar')
    end

    it 'should allow array as nested attributes' do
      actual_html = tag(:p, data: { foo: %i[bar baz] })
      assert_html_has_tag(actual_html, 'p', 'data-foo': 'bar baz')
    end

    it 'should build the exact attribute string' do
      assert_equal '<div class="x" />', tag(:div, data: {}, class: 'x')
      assert_equal '<br />', tag(:br, id: nil, hidden: false)
      assert_equal '<input checked="checked" name="a" />', tag(:input, checked: true, 'name' => 'a')
      assert_equal '<a href="/x" data-method="delete" rel="nofollow" data-confirm="Sure?" />',
                   tag(:a, href: '/x', method: :delete, confirm: 'Sure?')
    end

    it 'should not change the options it is given' do
      options = { class: 'btn', method: :delete }
      2.times { assert_equal '<a class="btn" data-method="delete" rel="nofollow" />', tag(:a, options) }
      assert_equal({ class: 'btn', method: :delete }, options)
    end

    it 'should escape the values that need it and leave the others as they are' do
      assert_equal '<input name="user[name]" value="Tom &amp; &lt;Jerry&gt; &quot;TJ&quot;" class="input" />',
                   tag(:input, name: 'user[name]', value: 'Tom & <Jerry> "TJ"', class: 'input')
    end

    it 'should escape a value whose only special character is a quote or an angle bracket' do
      assert_equal '<a title="say &quot;hi&quot;" />', tag(:a, title: 'say "hi"')
      assert_equal '<a title="&lt;b&gt;" />', tag(:a, title: '<b>')
      assert_equal '<a title="a&lt;b" />', tag(:a, title: 'a<b')
      assert_equal '<a title="a&gt;b" />', tag(:a, title: 'a>b')
    end

    it 'should write data attributes added to DATA_ATTRIBUTES' do
      Padrino::Helpers::TagHelpers::DATA_ATTRIBUTES.push(:dialog)
      assert_equal '<a data-dialog="true" />', tag(:a, dialog: true)
    ensure
      Padrino::Helpers::TagHelpers::DATA_ATTRIBUTES.delete(:dialog)
    end

    it 'should write Array, Symbol and Integer values' do
      assert_equal '<td class="a &amp; b c" id="cell" colspan="2" />', tag(:td, class: ['a & b', :c], id: :cell, colspan: 2)
    end

    it 'should write data attributes only for the options that ask for them' do
      assert_equal '<a href="/x" class="link" />', tag(:a, href: '/x', class: 'link')
      assert_equal '<a href="/x" data-method="post" rel="nofollow" data-remote="true" data-confirm="Sure &amp; certain?" />',
                   tag(:a, href: '/x', method: :post, remote: true, confirm: 'Sure & certain?')
    end

    it 'should write attribute names with each character a name cannot hold replaced by an underscore' do
      assert_equal '<div ___z="1" />', tag(:div, '"><z' => 1)
      assert_equal '<div a_b="1" c_d="2" />', tag(:div, 'a b' => 1, 'c=d': 2)
      assert_equal '<div a_b_c_d_e_f_g_="h" />', tag(:div, "a\tb\nc'd/e\u0000f<g>" => 'h')
      assert_equal '<input type="text" a_b="1" />', input_tag(:text, 'a b' => 1)
    end

    it 'should write nested attribute names the same way at every depth' do
      assert_equal '<div title-___z="1" />', tag(:div, title: { '"><z' => 1 })
      assert_equal '<div data-a_b="1" />', tag(:div, data: { 'a b' => 1 })
      assert_equal '<div data-x-y_z-q_r="2" />', tag(:div, data: { x: { 'y"z' => { 'q r': 2 } } })
      assert_equal '<div a_b-c="1" />', tag(:div, 'a b' => { c: 1 })
    end

    it 'should replace carriage returns, form feeds, other controls and DEL in attribute names' do
      assert_equal '<div a_b_c_d_e="1" />', tag(:div, "a\rb\fc\x01d\x7Fe" => 1)
    end

    it 'should write a valid attribute name given in another encoding in that encoding' do
      latin = "caf\xE9".dup.force_encoding(Encoding::ISO_8859_1)
      result = tag(:div, latin => 1)
      assert_equal %(<div #{latin}="1" />), result
      assert_equal Encoding::ISO_8859_1, result.encoding
      assert_equal %(<div data-#{latin}="1" />), tag(:div, data: { latin => 1 })
      result = tag(:div, 'données x'.b => 1)
      assert_equal '<div données_x="1" />'.b, result
      assert_equal Encoding::BINARY, result.encoding
    end

    it 'should replace characters a name cannot contain in names given in another ASCII-compatible encoding' do
      name = "a b<\u8868\u30BD".encode(Encoding::Shift_JIS)
      result = tag(:div, name => 1)
      assert_equal %(<div a_b_#{"\u8868\u30BD".encode(Encoding::Shift_JIS)}="1" />), result
      assert_equal Encoding::Shift_JIS, result.encoding
      assert_equal '<div a_b="1" />', tag(:div, 'a b'.b => 1)
      assert_equal '<_!x />', tag('!x'.b)
    end

    it 'should replace bytes that are not valid in a name given in another encoding' do
      result = tag(:div, "a\x81 b".dup.force_encoding(Encoding::Shift_JIS) => 1)
      assert_equal '<div a?_b="1" />', result
      assert_equal '<div caf??="1" />', tag(:div, 'café'.dup.force_encoding(Encoding::US_ASCII) => 1)
    end

    it 'should write a name in UTF-16 or UTF-32 as UTF-8' do
      assert_equal '<div a_b="1" />', tag(:div, 'a b'.encode(Encoding::UTF_16LE) => 1)
      assert_equal "<div data-caf\u00E9=\"1\" />", tag(:div, data: { 'café'.encode(Encoding::UTF_32BE) => 1 })
      assert_equal '<p>c</p>', content_tag('p'.encode(Encoding::UTF_16LE), 'c')
    end

    it 'should write a nested attribute name with bytes that are not valid UTF-8' do
      assert_equal "<div data-a\uFFFDb=\"1\" />", tag(:div, data: { "a\xFFb" => 1 })
    end

    it 'should start a tag name with a letter' do
      assert_equal '<_!-- class="k" />', tag(:'!--', class: 'k')
      assert_equal '<_?x>c</_?x>', content_tag('?x', 'c')
      assert_equal '<_ />', tag('')
      assert_equal '<_1x />', tag(:'1x')
      assert_equal '<my-element />', tag('my-element')
    end

    it 'should write a name and a value in the same encoding in that encoding' do
      result = tag(:div, "donn\xC3\xA9es".b => "\xC3\xA9".b)
      assert_equal "<div donn\xC3\xA9es=\"\xC3\xA9\" />".b, result
      assert_equal Encoding::BINARY, result.encoding
      name = "caf\xE9".dup.force_encoding(Encoding::ISO_8859_1)
      value = "\xE9t\xE9".dup.force_encoding(Encoding::ISO_8859_1)
      result = tag(:div, name => value)
      assert_equal %(<div #{name}="#{value}" />), result
      assert_equal Encoding::ISO_8859_1, result.encoding
    end

    it 'should replace bytes that are not valid in an attribute value' do
      assert_equal "<div title=\"a\uFFFDb\" />", tag(:div, title: "a\xFFb")
      result = tag(:div, title: "\x83\x5C\x81".dup.force_encoding(Encoding::Shift_JIS))
      assert_equal %(<div title="#{"\u30BD?".encode(Encoding::Shift_JIS)}" />), result
      assert_equal Encoding::Shift_JIS, result.encoding
    end

    it 'should not use methods of the object that includes the helpers' do
      helper = Class.new do
        include Padrino::Helpers::OutputHelpers
        include Padrino::Helpers::TagHelpers
        include Padrino::Helpers::AssetTagHelpers

        def tag_name(_name)
          'x'
        end

        def tag_attribute_name(_name)
          'y'
        end
      end.new
      assert_equal '<p />', helper.tag(:p)
      assert_equal '<a href="/">Home</a>', helper.link_to('Home', '/')
    end

    it 'should write an empty attribute name as an underscore' do
      assert_equal '<div _="v" />', tag(:div, '' => 'v')
      assert_equal '<div _="v" />', tag(:div, nil => 'v')
      assert_equal '<div _="v">c</div>', content_tag(:div, 'c', '': 'v')
    end

    it 'should replace characters a tag name cannot contain' do
      assert_equal '<p_onclick_x>c</p_onclick_x>', content_tag(:'p onclick=x', 'c')
      assert_equal '<br_x />', tag(:'br/x')
      assert_equal '<my-element data-x="1">c</my-element>', content_tag('my-element', 'c', data: { x: 1 })
    end

    it 'should write an attribute name with bytes that are not valid UTF-8' do
      assert_equal "<div a\uFFFDb=\"1\" />", tag(:div, "a\xFFb" => 1)
    end

    it 'should replace Unicode controls and noncharacters in attribute names' do
      assert_equal '<div a_b_c_d="1" />', tag(:div, "a\u0085b\uFDD0c\u{10FFFF}d" => 1)
    end

    it 'should leave valid attribute names as they are' do
      names = ['class', 'data-foo', 'aria-label', 'xml:lang', '@click', '@click.prevent', ':class', 'x-on:click',
               'x-bind:class', 'hx-on::after-request', 'v-on:click', '#default', ':[key]', '[value]', '(click)',
               '*ngIf', 'données', "\u540D\u524D", "a\u00A0b", 'a&b', '1x']
      names.each do |name|
        assert_equal %(<div #{name}="v" />), tag(:div, name => 'v')
        assert_equal %(<div #{name}="v" />), tag(:div, name.to_sym => 'v')
      end
      assert_equal '<div data-foo-bar="1" aria-label="l" />', tag(:div, data: { foo_bar: 1 }, aria: { label: 'l' })
    end
  end

  describe 'for #content_tag method' do
    it 'should support tags with content as parameter' do
      actual_html = content_tag(:p, 'Demo', class: 'large', id: 'thing')
      assert_html_has_tag(actual_html, 'p.large#thing', content: 'Demo')
    end

    it 'should support tags with content as block' do
      actual_html = content_tag(:p, class: 'large', id: 'star') { 'Demo' }
      assert_html_has_tag(actual_html, 'p.large#star', content: 'Demo')
    end

    it 'should escape non-html-safe content' do
      actual_html = content_tag(:p, class: 'large', id: 'star') { '<>' }
      assert_html_has_tag(actual_html, 'p.large#star')
      assert_match('&lt;&gt;', actual_html)
    end

    it 'should not escape html-safe content' do
      actual_html = content_tag(:p, class: 'large', id: 'star') { '<>' }
      assert_html_has_tag(actual_html, 'p.large#star', content: '<>')
    end

    it 'should write attribute names with each character a name cannot hold replaced by an underscore' do
      assert_equal '<p ___z="1" data-a_b="2">x</p>', content_tag(:p, 'x', '"><z' => 1, data: { 'a b' => 2 })
      assert_equal '<p a_b="1">x</p>', content_tag(:p, 'a"b': 1) { 'x' }
    end

    it 'should write content and attribute values in their encoding' do
      text = "donn\xC3\xA9es".b
      result = content_tag(:div, text, title: text)
      assert_equal %(<div title="#{text}">#{text}</div>), result
      assert_equal Encoding::BINARY, result.encoding
    end

    it 'should convert to a string if the content is not a string' do
      actual_html = content_tag(:p, 97)
      assert_html_has_tag(actual_html, 'p', content: '97')
    end

    it 'should support tags with erb' do
      get '/erb/content_tag'
      assert_response_has_tag :p, content: 'Test 1', class: 'test', id: 'test1'
      assert_response_has_tag :p, content: 'Test 2'
      assert_response_has_tag :p, content: 'Test 3'
      assert_response_has_tag :p, content: 'Test 4'
      assert_response_has_tag :p, content: 'one'
      assert_response_has_tag :p, content: 'two'
      assert_response_has_no_tag :p, content: 'failed'
    end

    it 'should support tags with haml' do
      get '/haml/content_tag'
      assert_response_has_tag :p, content: 'Test 1', class: 'test', id: 'test1'
      assert_response_has_tag :p, content: 'Test 2'
      assert_response_has_tag :p, content: 'Test 3', class: 'test', id: 'test3'
      assert_response_has_tag :p, content: 'Test 4'
      assert_response_has_tag :p, content: 'one'
      assert_response_has_tag :p, content: 'two'
      assert_response_has_no_tag :p, content: 'failed'
    end

    it 'should support tags with slim' do
      get '/slim/content_tag'
      assert_response_has_tag :p, content: 'Test 1', class: 'test', id: 'test1'
      assert_response_has_tag :p, content: 'Test 2'
      assert_response_has_tag :p, content: 'Test 3', class: 'test', id: 'test3'
      assert_response_has_tag :p, content: 'Test 4'
      assert_response_has_tag :p, content: 'one'
      assert_response_has_tag :p, content: 'two'
      assert_response_has_no_tag :p, content: 'failed'
    end
  end

  describe 'for #input_tag method' do
    it 'should support field with type' do
      assert_html_has_tag(input_tag(:text), 'input[type=text]')
    end

    it 'should support field with type and options' do
      actual_html = input_tag(:text, class: 'first', id: 'texter')
      assert_html_has_tag(actual_html, 'input.first#texter[type=text]')
    end

    it 'should support checked attribute by using "checked" if true' do
      actual_html = input_tag(:checkbox, checked: true)
      assert_html_has_tag(actual_html, 'input[type=checkbox]', checked: 'checked')
    end

    it 'should remove checked attribute if false' do
      actual_html = input_tag(:checkbox, checked: false)
      assert_html_has_no_tag(actual_html, 'input[type=checkbox][checked=false]')
    end

    it 'should support disabled attribute by using "disabled" if true' do
      actual_html = input_tag(:checkbox, disabled: true)
      assert_html_has_tag(actual_html, 'input[type=checkbox]', disabled: 'disabled')
    end
  end
end
