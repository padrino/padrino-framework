require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Message" do

  context 'the message' do
    should "accept headers and body" do
      message = Mail::Message.new do
        from    'padrino@me.com'
        to      'padrino@you.com'
        subject 'Hello there Padrino'
        body    'This is a body of text'
      end

      assert_equal ['padrino@me.com'],       message.from
      assert_equal ['padrino@you.com'],      message.to
      assert_equal 'Hello there Padrino',    message.subject
      assert_equal 'This is a body of text', message.body.to_s.chomp
    end

    should "raise an error if template was not found" do
      assert_raises Padrino::Rendering::TemplateNotFound do
        Mail::Message.new do
          from    'padrino@me.com'
          to      'padrino@you.com'
          subject 'Hello there Padrino'
          render  'foo/bar'
        end
      end
    end

    should "use locals" do
      message = Mail::Message.new do
        from    'padrino@me.com'
        to      'padrino@you.com'
        subject 'Hello there Padrino'
        locals  :foo => "Im Foo!"
        body    erb("<%= foo %>")
      end

      assert_equal ['padrino@me.com'],    message.from
      assert_equal ['padrino@you.com'],   message.to
      assert_equal 'Hello there Padrino', message.subject
      assert_equal 'Im Foo!',             message.body.to_s.chomp
    end

    should "use views paths" do
      message = Mail::Message.new do
        views   File.dirname(__FILE__) + '/fixtures/views/mailers'
        from    'padrino@me.com'
        to      'padrino@you.com'
        subject 'Hello there Padrino'
        render  :bar
      end

      assert_equal ['padrino@me.com'],    message.from
      assert_equal ['padrino@you.com'],   message.to
      assert_equal 'Hello there Padrino', message.subject
      assert_equal 'This is a bar message in mailers dir', message.body.to_s.chomp
    end

    should "use views and mailers paths" do
      message = Mail::Message.new do
        views   File.dirname(__FILE__) + '/fixtures/views/mailers'
        from    'padrino@me.com'
        to      'padrino@you.com'
        subject 'Hello there Padrino'
        render  'alternate/foo'
      end

      assert_equal ['padrino@me.com'],    message.from
      assert_equal ['padrino@you.com'],   message.to
      assert_equal 'Hello there Padrino', message.subject
      assert_equal 'This is a foo message in mailers/alternate dir', message.body.to_s.chomp
    end

    should "use layouts" do
      message = Mail::Message.new do
        views   File.dirname(__FILE__) + '/fixtures/views/mailers'
        from    'padrino@me.com'
        to      'padrino@you.com'
        subject 'Hello there Padrino'
        render  'sample/foo', :layout => :"layouts/sample"
      end

      assert_equal ['padrino@me.com'],    message.from
      assert_equal ['padrino@you.com'],   message.to
      assert_equal 'Hello there Padrino', message.subject
      assert_equal 'Layout Sample This is a foo message in mailers/sample dir', message.body.to_s.strip
    end

    should "use i18n" do
      I18n.locale = :en

      message = Mail::Message.new do
        views   File.dirname(__FILE__) + '/fixtures/views/mailers'
        from    'padrino@me.com'
        to      'padrino@you.com'
        subject 'Hello there Padrino'
        render  'i18n/hello'
      end

      assert_equal ['padrino@me.com'],    message.from
      assert_equal ['padrino@you.com'],   message.to
      assert_equal 'Hello there Padrino', message.subject
      assert_equal 'Hello World',         message.body.to_s.chomp

      I18n.locale = :it

      message = Mail::Message.new do
        views   File.dirname(__FILE__) + '/fixtures/views/mailers'
        from    'padrino@me.com'
        to      'padrino@you.com'
        subject 'Hello there Padrino'
        render  'i18n/hello'
      end

      assert_equal ['padrino@me.com'],    message.from
      assert_equal ['padrino@you.com'],   message.to
      assert_equal 'Hello there Padrino', message.subject
      assert_equal 'Salve Mondo',         message.body.to_s.chomp
    end

    should "auto lookup template for the given content_type" do
      message = Mail::Message.new do
        views        File.dirname(__FILE__) + '/fixtures/views/mailers'
        from         'padrino@me.com'
        to           'padrino@you.com'
        subject      'Hello there Padrino'
        content_type 'text/html'
        render       'multipart/basic'
      end

      assert_equal ['padrino@me.com'],    message.from
      assert_equal ['padrino@you.com'],   message.to
      assert_equal 'Hello there Padrino', message.subject
      assert_equal 'text html',           message.body.to_s.chomp

      message = Mail::Message.new do
        views        File.dirname(__FILE__) + '/fixtures/views/mailers'
        from         'padrino@me.com'
        to           'padrino@you.com'
        subject      'Hello there Padrino'
        content_type :plain
        render       'multipart/basic'
      end

      assert_equal ['padrino@me.com'],    message.from
      assert_equal ['padrino@you.com'],   message.to
      assert_equal 'Hello there Padrino', message.subject
      assert_equal 'plain text',          message.body.to_s.chomp
    end
  end
end
