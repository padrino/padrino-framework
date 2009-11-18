require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/fixtures/markup_app/app'

class TestFormatHelpers < Test::Unit::TestCase
  def app
    MarkupDemo.tap { |app| app.set :environment, :test }
  end

  include Padrino::Helpers::FormatHelpers

  context 'for #h and #h! method' do
    should "escape the simple html" do
      assert_equal '&lt;h1&gt;hello&lt;/h1&gt;', h('<h1>hello</h1>')
      assert_equal '&lt;h1&gt;hello&lt;/h1&gt;', escape_html('<h1>hello</h1>')
    end
    should "escape all brackets, quotes and ampersands" do
      assert_equal '&lt;h1&gt;&lt;&gt;&quot;&amp;demo&amp;&quot;&lt;&gt;&lt;/h1&gt;', h('<h1><>"&demo&"<></h1>')
    end
    should "return default text if text is empty" do
      assert_equal 'default', h!("", "default")
      assert_equal '&nbsp;', h!("")
    end
    should "return text escaped if not empty" do
      assert_equal '&lt;h1&gt;hello&lt;/h1&gt;', h!('<h1>hello</h1>')
    end
  end

  context 'for #time_in_words method' do
    should "display today" do
      assert_equal 'today', time_in_words(Time.now)
    end
    should "display yesterday" do
      assert_equal 'yesterday', time_in_words(1.day.ago)
    end
    should "display tomorrow" do
      assert_equal 'tomorrow', time_in_words(1.day.from_now)
    end
    should "return future number of days" do
      assert_equal 'in 4 days', time_in_words(4.days.from_now)
    end
    should "return past days ago" do
      assert_equal '4 days ago', time_in_words(4.days.ago)
    end
    should "return formatted archived date" do
      assert_equal 100.days.ago.strftime('%A, %B %e'), time_in_words(100.days.ago)
    end
    should "return formatted archived year date" do
      assert_equal 500.days.ago.strftime('%A, %B %e, %Y'), time_in_words(500.days.ago)
    end
  end

  context 'for #relative_time_ago method' do
    should 'display now as a minute ago' do
      assert_equal 'about a minute', relative_time_ago(1.minute.ago)
    end
    should "display a few minutes ago" do
      assert_equal '4 minutes', relative_time_ago(4.minute.ago)
    end
    should "display an hour ago" do
      assert_equal 'about 1 hour', relative_time_ago(1.hour.ago + 5.minutes.ago.sec)
    end
    should "display a few hours ago" do
      assert_equal 'about 3 hours', relative_time_ago(3.hour.ago + 5.minutes.ago.sec)
    end
    should "display a day ago" do
      assert_equal '1 day', relative_time_ago(1.day.ago)
    end
    should "display a few days ago" do
      assert_equal '5 days', relative_time_ago(5.days.ago - 5.minutes.ago.sec)
    end
    should "display a month ago" do
      assert_equal 'about 1 month', relative_time_ago(32.days.ago + 5.minutes.ago.sec)
    end
    should "display a few months ago" do
      assert_equal '6 months', relative_time_ago(180.days.ago - 5.minutes.ago.sec)
    end
    should "display a year ago" do
      assert_equal 'about 1 year', relative_time_ago(365.days.ago - 5.minutes.ago.sec)
    end
    should "display a few years ago" do
      assert_equal 'over 7 years', relative_time_ago(2800.days.ago - 5.minutes.ago.sec)
    end
  end

  context 'for #escape_javascript method' do
    should "escape double quotes" do
      assert_equal "\"hello\"", escape_javascript('"hello"')
    end
    should "escape single quotes" do
      assert_equal "\"hello\"", escape_javascript("'hello'")
    end
    should "escape html tags and breaks" do
      assert_equal "\"\\n<p>hello<\\/p>\\n\"", escape_javascript("\n\r<p>hello</p>\r\n")
    end
  end
end
