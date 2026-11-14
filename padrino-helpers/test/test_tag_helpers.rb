require_relative 'helper'
require_relative 'fixtures/markup_app/app'
require 'bigdecimal'

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

    it 'should write BigDecimal values in plain decimal notation' do
      {
        '9.99' => '9.99', '-9.99' => '-9.99', '9.50' => '9.5', '10' => '10', '0' => '0',
        '1e20' => '100000000000000000000', '0.0000001' => '0.0000001', '-0.0001' => '-0.0001',
        'NaN' => 'NaN', 'Infinity' => 'Infinity', '-Infinity' => '-Infinity'
      }.each do |given, written|
        assert_equal %(<input value="#{written}" />), tag(:input, value: BigDecimal(given))
      end
      assert_equal '<a data-geo="1.5 -0.25" />', tag(:a, data: { geo: [BigDecimal('1.5'), BigDecimal('-0.25')] })
    end

    it 'should keep the scientific form for a very large or small exponent' do
      assert_equal '<input value="0.1e1000001" />', tag(:input, value: BigDecimal('1e1000000'))
      assert_equal '<input value="0.1e-999999" />', tag(:input, value: BigDecimal('1e-1000000'))
      assert_equal '<input value="0.1e101" />', tag(:input, value: BigDecimal('1e100'))
      assert_equal '<input value="0.1e-101" />', tag(:input, value: BigDecimal('1e-102'))
      assert_equal %(<input value="1#{'0' * 99}" />), tag(:input, value: BigDecimal('1e99'))
      assert_equal %(<input value="0.#{'0' * 100}1" />), tag(:input, value: BigDecimal('1e-101'))
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

    it 'should write the boolean attributes of the HTML standard by name' do
      assert_equal '<details open="open" />', tag(:details, open: true)
      assert_equal '<script async="async" nomodule="nomodule" />', tag(:script, async: true, nomodule: true)
      assert_equal '<video controls="controls" playsinline="playsinline" />', tag(:video, controls: true, playsinline: true)
      assert_equal '<div inert="inert" />', tag(:div, inert: true)
      assert_equal '<input disabled="disabled" />', tag(:input, 'disabled' => true)
      assert_equal '<details />', tag(:details, open: false)
    end

    it 'should keep a String given to a boolean attribute' do
      assert_equal '<div hidden="until-found" />', tag(:div, hidden: 'until-found')
      assert_equal '<div hidden="hidden" />', tag(:div, hidden: true)
      assert_equal '<div />', tag(:div, hidden: false)
      assert_equal '<div hidden="until-found" />', tag(:div, hidden: :'until-found')
      assert_equal '<input disabled="disabled" />', tag(:input, disabled: 1)
    end

    it 'should write popover as empty when true and keep its keyword otherwise' do
      assert_equal '<div popover="" />', tag(:div, popover: true)
      assert_equal '<div popover="manual" />', tag(:div, popover: 'manual')
      assert_equal '<div />', tag(:div, popover: false)
    end

    it 'should write false for aria attributes and the true/false enumerated attributes' do
      assert_equal '<div aria-hidden="false" spellcheck="false" draggable="false" contenteditable="false" />',
                   tag(:div, 'aria-hidden': false, spellcheck: false, draggable: false, contenteditable: false)
      assert_equal '<div aria-expanded="false" aria-current="false" />', tag(:div, 'aria-expanded' => false, 'aria-current': false)
      assert_equal '<div aria-hidden="false" />', tag(:div, aria: { hidden: false })
      assert_equal '<div spellcheck="true" />', tag(:div, spellcheck: true)
      assert_equal '<div />', tag(:div, 'aria-hidden': nil, spellcheck: nil, title: false)
    end

    it 'should drop false for ARIA attributes whose values are not true/false states' do
      assert_equal '<td />', tag(:td, 'aria-label': false, 'aria-describedby': false, 'aria-labelledby' => false)
    end

    it 'should build class from Arrays and Hashes of names' do
      assert_equal '<div class="a b" />', tag(:div, class: ['a', nil, '', 'b'])
      assert_equal '<div class="active" />', tag(:div, class: { active: true, off: false })
      assert_equal '<div class="btn &amp; active" />', tag(:div, class: ['btn &', [{ active: 1, off: nil }], false])
      assert_equal '<div class="x" />', tag(:div, 'class' => { x: true })
      assert_equal '<div id="a" />', tag(:div, class: { off: false }, id: 'a')
      assert_equal '<div />', tag(:div, class: [])
      assert_equal '<p class="on">x</p>', content_tag(:p, 'x', class: { on: true })
    end

    it 'should write data attributes only for the options that ask for them' do
      assert_equal '<a href="/x" class="link" />', tag(:a, href: '/x', class: 'link')
      assert_equal '<a href="/x" data-method="post" rel="nofollow" data-remote="true" data-confirm="Sure &amp; certain?" />',
                   tag(:a, href: '/x', method: :post, remote: true, confirm: 'Sure & certain?')
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

    it 'should convert to a string if the content is not a string' do
      actual_html = content_tag(:p, 97)
      assert_html_has_tag(actual_html, 'p', content: '97')
    end

    it 'should write BigDecimal content in plain decimal notation' do
      assert_equal '<td>9.99</td>', content_tag(:td, BigDecimal('9.99'))
    end

    it 'should write BigDecimal items of a content list in plain decimal notation' do
      assert_equal "<td>9.99\n10\n</td>", content_tag(:td, [BigDecimal('9.99'), BigDecimal('10')])
      assert_equal "<td>10\n</td>", content_tag(:td, [10])
    end

    it 'should write other numbers as they are' do
      assert_equal '<td>10.0</td>', content_tag(:td, 10.0)
      assert_equal '<input value="10.0" size="10" />', tag(:input, value: 10.0, size: 10)
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

  describe 'for #class_names method' do
    it 'should join Strings, Symbols and other values' do
      assert_equal 'btn primary 2', class_names('btn', :primary, 2)
    end

    it 'should split Strings on whitespace' do
      assert_equal 'btn btn-lg primary', class_names("  btn\tbtn-lg\n", ' primary ')
    end

    it 'should split Strings only on ASCII whitespace' do
      assert_equal "a\u00a0b c\u3000d", class_names("a\u00a0b", "c\u3000d")
    end

    it 'should split and dedupe Hash keys as other values' do
      assert_equal 'a b x y', class_names('a', { 'a b' => true, %w[x y] => true })
    end

    it 'should keep the Hash keys whose values are truthy' do
      assert_equal 'active is-big a b', class_names(active: true, disabled: false, open: nil, 'is-big' => 1, 'a b' => 'yes')
    end

    it 'should flatten nested Arrays and the Hashes in them' do
      assert_equal 'card card--wide shadow selected', class_names(['card', ['card--wide', [:shadow, { selected: true, off: false }]]])
    end

    it 'should keep each name once, where it first appears' do
      assert_equal 'b a c', class_names('b a', :a, %w[b c], { c: true }, 'a b')
    end

    it 'should leave out nil, false and blank values' do
      assert_equal 'x', class_names(nil, 'x', false)
      assert_equal '', class_names(nil, false, '', " \t ", [], {}, [nil, false], { nil => true, '' => true })
      assert_equal '', class_names
    end

    it 'should return a String that is not marked html_safe and leave its arguments alone' do
      buffer = 'btn <b>'.html_safe
      names = ['a b', { 'c' => true }]
      result = class_names(buffer, names)
      assert_equal 'btn <b> a b c', result
      assert_instance_of String, result
      refute result.html_safe?
      assert_equal 'btn <b>', buffer
      assert_equal ['a b', { 'c' => true }], names
    end

    it 'should be escaped when written into a class attribute' do
      assert_equal '<div class="say&quot;hi &lt;b&gt;&amp;">x</div>',
                   content_tag(:div, 'x', class: class_names('say"hi', { '<b>&' => true }))
      assert_equal '<hr class="a&quot; b" />', tag(:hr, class: class_names('a"', :b, 'a"'))
    end
  end
end
