require_relative 'helper'
require_relative 'fixtures/markup_app/app'

describe 'FormatHelpers' do
  include Padrino::Helpers::FormatHelpers

  def app
    MarkupDemo
  end

  def setup
    Time.stubs(:now).returns(Time.utc(1983, 11, 9, 5))
  end

  describe 'for #simple_format method' do
    it 'should format simple text into html format' do
      actual_text = simple_format("Here is some basic text...\n...with a line break.")
      assert actual_text.html_safe?
      assert_equal "<p>Here is some basic text...\n<br />...with a line break.</p>", actual_text
    end

    it 'should format more text into html format' do
      actual_text = simple_format("We want to put a paragraph...\n\n...right there.")
      assert_equal "<p>We want to put a paragraph...</p>\n\n<p>...right there.</p>", actual_text
    end

    it 'should support defining a class for the paragraphs' do
      actual_text = simple_format('Look me! A class!', class: 'description')
      assert_equal '<p class="description">Look me! A class!</p>', actual_text
    end

    it 'should escape html tags' do
      actual_text = simple_format('Will you escape <b>that</b>?')
      assert_equal '<p>Will you escape &lt;b&gt;that&lt;/b&gt;?</p>', actual_text
    end

    it 'should support already sanitized text' do
      actual_text = simple_format("Don't try to escape <b>me</b>!".html_safe)
      assert_equal "<p>Don't try to escape <b>me</b>!</p>", actual_text
    end

    it 'should not modify already sanitized text it is given' do
      text = "Keep me\nas I am".html_safe
      simple_format(text)
      assert_equal "Keep me\nas I am", text
      assert_equal "<p>Keep me\n<br />as I am</p>", simple_format(text.freeze)
    end

    describe 'wrapped in a custom tag' do
      it 'should format simple text into html format' do
        actual_text = simple_format("Here is some basic text...\n...with a line break.", tag: :div)
        assert_equal "<div>Here is some basic text...\n<br />...with a line break.</div>", actual_text
      end

      it 'should format more text into html format' do
        actual_text = simple_format("We want to put a paragraph...\n\n...right there.", tag: :div)
        assert_equal "<div>We want to put a paragraph...</div>\n\n<div>...right there.</div>", actual_text
      end

      it 'should support defining a class for the paragraphs' do
        actual_text = simple_format('Look me! A class!', class: 'description', tag: :div)
        assert_equal '<div class="description">Look me! A class!</div>', actual_text
      end
    end
  end

  describe 'for #pluralize method' do
    it 'should pluralize with the given count' do
      assert_equal '1 person', pluralize(1, 'person')
      assert_equal '2 people', pluralize(2, 'person')
      assert_equal '2 folks', pluralize(2, 'person', 'folks')
    end

    it 'should pluralize without String#pluralize from ActiveSupport or padrino-gen' do
      hidden = String.method_defined?(:pluralize)
      if hidden
        String.send(:alias_method, :__hidden_pluralize, :pluralize)
        String.send(:remove_method, :pluralize)
      end
      assert_equal '2 items', pluralize(2, 'item')
    ensure
      if hidden
        String.send(:alias_method, :pluralize, :__hidden_pluralize)
        String.send(:remove_method, :__hidden_pluralize)
      end
    end
  end

  describe 'for #word_wrap method' do
    it 'should return proper formatting for 8 max width' do
      actual_text = word_wrap('Once upon a time', line_width: 8)
      assert_equal "Once\nupon a\ntime", actual_text
    end
    it 'should return proper formatting for 1 max width' do
      actual_text = word_wrap('Once upon a time', line_width: 1)
      assert_equal "Once\nupon\na\ntime", actual_text
    end
    it 'should return proper formatting for default width' do
      actual_text = word_wrap((1..50).to_a.join(' '))
      assert_equal "#{(1..30).to_a.join(' ')}\n#{(31..50).to_a.join(' ')}", actual_text
      actual_text = word_wrap((1..50).to_a.join(' '), 80)
      assert_equal "#{(1..30).to_a.join(' ')}\n#{(31..50).to_a.join(' ')}", actual_text
    end
  end

  describe 'for #highlight method' do
    it 'should highligth with defaults' do
      actual_text = highlight('Lorem ipsum dolor sit amet', 'dolor')
      assert_equal 'Lorem ipsum <strong class="highlight">dolor</strong> sit amet', actual_text
    end

    it 'should highlight with highlighter' do
      actual_text = highlight('Lorem ipsum dolor sit amet', 'dolor', highlighter: '<span class="custom">\1</span>')
      assert_equal 'Lorem ipsum <span class="custom">dolor</span> sit amet', actual_text
    end

    it 'should leave words inside html tags alone' do
      actual_text = highlight('<b class="b">bold</b> <a href="/b">b</a>', 'b')
      assert_equal '<b class="b"><strong class="highlight">b</strong>old</b> <a href="/b"><strong class="highlight">b</strong></a>', actual_text
    end

    it 'should leave a quoted attribute alone when it holds a >' do
      actual_text = highlight('<a title="x > y">y</a>', 'y')
      assert_equal '<a title="x > y"><strong class="highlight">y</strong></a>', actual_text
    end

    it 'should leave a quoted attribute alone when it holds a <' do
      actual_text = highlight(%(<a title="x < y" data-y='y < x'>y</a>), 'y')
      assert_equal %(<a title="x < y" data-y='y < x'><strong class="highlight">y</strong></a>), actual_text
    end

    it 'should highlight text around a < that does not start a tag' do
      assert_equal 'if a < b then <strong class="highlight">y</strong>', highlight('if a < b then y', 'y')
      assert_equal 'if <strong class="highlight">a < b</strong> then y', highlight('if a < b then y', 'a < b')
      assert_equal "<\u212A <strong class=\"highlight\">b</strong>", highlight("<\u212A b", 'b')
    end

    it 'should read a quote in a tag as a value only after =' do
      actual_text = highlight("<img alt=it's> Ruby isn't", 'ruby')
      assert_equal %(<img alt=it's> <strong class="highlight">Ruby</strong> isn't), actual_text
    end

    it 'should not split a tag at its closing >' do
      assert_equal '<b>x</b>', highlight('<b>x</b>', '>x')
    end

    it 'should highlight long text in linear time' do
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      actual_text = highlight('word ' * 20_000, 'word')
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 2
      assert_equal '<strong class="highlight">word</strong> ' * 20_000, actual_text
    end

    it 'should highlight html safe text' do
      actual_text = highlight('<p>Lorem</p><p>ipsum dolor</p>'.html_safe, %w[lorem dolor])
      assert_equal '<p><strong class="highlight">Lorem</strong></p><p>ipsum <strong class="highlight">dolor</strong></p>', actual_text
    end

    it 'should highlight several words across tags' do
      actual_text = highlight('<p>Lorem</p><p>ipsum lorem</p>', %w[lorem ipsum])
      assert_equal '<p><strong class="highlight">Lorem</strong></p><p><strong class="highlight">ipsum</strong> <strong class="highlight">lorem</strong></p>', actual_text
    end
  end

  describe 'for #truncate method' do
    it 'should support default truncation' do
      actual_text = truncate('Once upon a time in a world far far away')
      assert_equal 'Once upon a time in a world...', actual_text
    end
    it 'should support specifying length' do
      actual_text = truncate('Once upon a time in a world far far away', length: 14)
      assert_equal 'Once upon a...', actual_text
    end
    it 'should support specifying omission text' do
      actual_text = truncate('And they found that many people were sleeping better.', length: 25, omission: '(clipped)')
      assert_equal 'And they found t(clipped)', actual_text
    end
    it 'should not return more text when the length is shorter than the omission' do
      assert_equal '...', truncate('hello world', length: 2)
      assert_equal '(cut)', truncate('hello world', length: 3, omission: '(cut)')
    end
  end

  describe 'for #truncate_words method' do
    it 'should support default truncation' do
      actual_text = truncate_words(<<~TEXT.chomp)
        Long before books were made, people told stories. They told them to one another and to the children as they sat before the fire. Many of these stories were about interesting people,
        but most of them were about the ways of fairies and giants.
      TEXT
      assert_equal 'Long before books were made, people told stories. They told them to one another and to the children as they sat before the fire. Many of these stories were about...', actual_text
    end
    it 'should support specifying length' do
      actual_text = truncate_words('Once upon a time in a world far far away', length: 8)
      assert_equal 'Once upon a time in a world far...', actual_text
    end
    it 'should support specifying omission text' do
      actual_text = truncate_words('And they found that many people were sleeping better.', length: 4, omission: '(clipped)')
      assert_equal 'And they found that(clipped)', actual_text
    end
    it 'should keep no words for a length of zero' do
      assert_equal '...', truncate_words('one two three', length: 0)
    end
  end

  describe 'for #h and #h! method' do
    it 'should escape the simple html' do
      assert_equal '&lt;h1&gt;hello&lt;/h1&gt;', h('<h1>hello</h1>')
      assert_equal '&lt;h1&gt;hello&lt;/h1&gt;', escape_html('<h1>hello</h1>')
    end
    it 'should escape all brackets, quotes and ampersands' do
      assert_equal '&lt;h1&gt;&lt;&gt;&quot;&amp;demo&amp;&quot;&lt;&gt;&lt;/h1&gt;', h('<h1><>"&demo&"<></h1>')
    end
    it 'should return default text if text is empty' do
      assert_equal 'default', h!('', 'default')
      assert_equal '&nbsp;', h!('')
    end
    it 'should return text escaped if not empty' do
      assert_equal '&lt;h1&gt;hello&lt;/h1&gt;', h!('<h1>hello</h1>')
    end
    it 'should mark escaped text as safe' do
      refute '<h1>hello</h1>'.html_safe?
      assert h('<h1>hello</h1>').html_safe?
      assert h!('', 'default').html_safe?
    end
  end

  describe 'for #time_ago_in_words method' do
    A_DAY = 24 * 60 * 60

    it 'should less than 5 seconds' do
      assert_equal 'less than 5 seconds', time_ago_in_words(Time.now, true)
    end
    it 'should less than 10 seconds' do
      assert_equal 'less than 10 seconds', time_ago_in_words(Time.now - 5, true)
    end
    it 'should less than 20 seconds' do
      assert_equal 'less than 20 seconds', time_ago_in_words(Time.now - 10, true)
    end
    it 'should less than a minute' do
      assert_equal 'less than a minute', time_ago_in_words(Time.now - 40, true)
    end
    it 'should 2 minutes' do
      assert_equal '2 minutes', time_ago_in_words(Time.now - 120, true)
    end
    it 'should display today' do
      assert_equal 'less than a minute', time_ago_in_words(Time.now)
    end
    it 'should display yesterday' do
      assert_equal '1 day', time_ago_in_words(Time.now - A_DAY)
    end
    it 'should display tomorrow' do
      assert_equal '1 day', time_ago_in_words(Time.now + A_DAY)
    end
    it 'should return future number of days' do
      assert_equal '4 days', time_ago_in_words(Time.now + 4 * A_DAY)
    end
    it 'should return past days ago' do
      assert_equal '4 days', time_ago_in_words(Time.now - 4 * A_DAY)
    end
    it 'should return formatted archived date' do
      assert_equal '3 months', time_ago_in_words(Time.now - 100 * A_DAY)
    end
    it 'should return formatted archived year date' do
      assert_equal 'over 1 year', time_ago_in_words(Time.now - 500 * A_DAY)
    end
    it 'should display now as a minute ago' do
      assert_equal '1 minute', time_ago_in_words(Time.now - 60)
    end
    it 'should display a few minutes ago' do
      assert_equal '4 minutes', time_ago_in_words(Time.now - 4 * 60)
    end
    it 'should display an hour ago' do
      assert_equal 'about 1 hour', time_ago_in_words(Time.now - 60 * 60 + 5)
    end
    it 'should display a few hours ago' do
      assert_equal 'about 3 hours', time_ago_in_words(Time.now - 3 * 60 * 60 + 5 * 60)
    end
    it 'should display a few days ago' do
      assert_equal '5 days', time_ago_in_words(Time.now - 5 * A_DAY - 5 * 60)
    end
    it 'should display a month ago' do
      assert_equal 'about 1 month', time_ago_in_words(Time.now - 32 * A_DAY + 5 * 60)
    end
    it 'should display a few months ago' do
      assert_equal '6 months', time_ago_in_words(Time.now - 180 * A_DAY - 5 * 60)
    end
    it 'should display a year ago' do
      assert_equal 'about 1 year', time_ago_in_words(Time.now - 365 * A_DAY - 5 * 60)
    end
    it 'should display a few years ago' do
      assert_equal 'over 7 years', time_ago_in_words(Time.now - 2800 * A_DAY - 5 * 60)
    end
  end

  describe 'for #js_escape_html method' do
    it 'should escape double quotes' do
      assert_equal '\"hello\"', js_escape_html('"hello"')
      assert_equal '\"hello\"', js_escape_html(Padrino::SafeBuffer.new('"hello"'))
    end
    it 'should escape single quotes' do
      assert_equal "\\'hello\\'", js_escape_html("'hello'")
      assert_equal "\\'hello\\'", js_escape_html(Padrino::SafeBuffer.new("'hello'"))
    end
    it 'should escape html tags and breaks' do
      assert_equal '\\n\\n<p>hello<\\/p>\\n', js_escape_html("\n\r<p>hello</p>\r\n")
      assert_equal '\\n\\n<p>hello<\\/p>\\n', js_escape_html(Padrino::SafeBuffer.new("\n\r<p>hello</p>\r\n"))
    end
    it 'should escape data-confirm attribute' do
      assert_equal '<data-confirm=\"are you sure\">', js_escape_html('<data-confirm="are you sure">')
      assert_equal '<data-confirm=\"are you sure\">', js_escape_html(Padrino::SafeBuffer.new('<data-confirm="are you sure">'))
    end
    it 'should keep html_safe content html_safe' do
      refute js_escape_html('"hello"').html_safe?
      assert js_escape_html(Padrino::SafeBuffer.new('"hello"')).html_safe?
    end
  end
end
