require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Part" do
  describe "the part" do
    it 'should use correctly parts' do
      message = Mail::Message.new do
        views   File.dirname(__FILE__) + '/fixtures/views/mailers'
        to      'padrino@test.lindsaar.net'
        subject 'nested multipart'
        from    'test@example.com'

        text_part do
          body 'plain text'
        end

        html_part do
          render  'sample/foo'
        end

        part do
          body 'other'
        end
      end

      refute_nil message.html_part
      refute_nil message.text_part
      assert_equal 4, message.parts.length
      assert_equal :plain, message.parts[0].content_type
      assert_equal 'plain text', message.parts[0].body.decoded
      assert_equal :html, message.parts[1].content_type
      assert_equal 'This is a foo message in mailers/sample dir', message.parts[1].body.decoded.chomp
      assert_equal :plain, message.parts[2].content_type
      assert_equal 'other', message.parts[2].body.decoded

      assert_equal 'This is a foo message in mailers/sample dir', message.html_part.body.decoded.chomp
    end

    it 'should works with multipart templates' do
      message = Mail::Message.new do
        views   File.dirname(__FILE__) + '/fixtures/views/mailers'
        to      'padrino@test.lindsaar.net'
        subject 'nested multipart'
        from    'test@example.com'

        text_part do
          render  'multipart/basic.text'
        end

        html_part do
          render  'multipart/basic.html'
        end
      end

      refute_nil message.html_part
      refute_nil message.text_part
      assert_equal 2, message.parts.length
      assert_equal :plain, message.parts[0].content_type
      assert_equal 'plain text', message.parts[0].body.decoded.chomp
      assert_equal :html, message.parts[1].content_type
      assert_equal 'text html', message.parts[1].body.decoded.chomp
    end

    it 'should works with less explict multipart templates' do
      message = Mail::Message.new do
        views   File.dirname(__FILE__) + '/fixtures/views/mailers'
        to      'padrino@test.lindsaar.net'
        subject 'nested multipart'
        from    'test@example.com'

        text_part { render('multipart/basic.plain') }
        html_part { render('multipart/basic.html')  }
      end

      refute_nil message.html_part
      refute_nil message.text_part
      assert_equal 2, message.parts.length
      assert_equal :plain, message.parts[0].content_type
      assert_equal 'plain text', message.parts[0].body.decoded.chomp
      assert_equal :html, message.parts[1].content_type
      assert_equal 'text html', message.parts[1].body.decoded.chomp
    end

    it 'should works with provides' do
      message = Mail::Message.new do
        views   File.dirname(__FILE__) + '/fixtures/views/mailers'
        to      'padrino@test.lindsaar.net'
        subject 'nested multipart'
        from    'test@example.com'
        provides :plain, :html
        render  'multipart/basic'
      end

      assert_match /^multipart\/alternative/, message['content-type'].value
      assert_equal 2, message.parts.length
      assert_equal :plain, message.parts[0].content_type
      assert_equal 'plain text', message.parts[0].body.decoded.chomp
      assert_equal :html, message.parts[1].content_type
      assert_equal 'text html', message.parts[1].body.decoded.chomp
    end

    # it 'should provide a way to instantiate a new part as you go down' do
    #   message = Mail::Message.new do
    #     to           'padrino@test.lindsaar.net'
    #     subject      "nested multipart"
    #     from         "test@example.com"
    #     content_type "multipart/mixed"
    #
    #     part :content_type => "multipart/alternative", :content_disposition => "inline", :headers => { "foo" => "bar" } do |p|
    #       p.part :content_type => "text/plain", :body => "test text\nline #2"
    #       p.part :content_type => "text/html",  :body => "<b>test</b> HTML<br/>\nline #2"
    #     end
    #   end
    #
    #   assert_equal 2, message.parts.first.parts.length
    #   assert_equal :plain, message.parts.first.parts[0].content_type
    #   assert_equal "test text\nline #2", message.parts.first.parts[0].body.decoded
    #   assert_equal :html, message.parts.first.parts[1].content_type
    #   assert_equal "<b>test</b> HTML<br/>\nline #2", message.parts.first.parts[1].body.decoded
    # end
  end
end
