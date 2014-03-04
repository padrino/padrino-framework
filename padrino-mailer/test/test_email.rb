require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Email" do
  describe 'the mailer in an app' do
    it 'should send a basic inline email' do
      mock_app do
        register Padrino::Mailer
        get "/" do
          email do
            from    'padrino@me.com'
            to      'padrino@you.com'
            subject 'Hello there Padrino'
            body    'Body'
            via     :test
          end
        end
      end
      get "/"
      assert ok?
      email = pop_last_delivery
      assert_equal ['padrino@me.com'],    email.from
      assert_equal ['padrino@you.com'],   email.to
      assert_equal 'Hello there Padrino', email.subject
      assert_equal 'Body',                email.body.to_s
    end

    it 'should send a basic inline from hash' do
      mock_app do
        register Padrino::Mailer
        get "/" do
          email({
            :from    => 'padrino@me.com',
            :to      => 'padrino@you.com',
            :subject => 'Hello there Padrino',
            :body    => 'Body',
            :via     => :test
          })
        end
      end
      get "/"
      assert ok?
      email = pop_last_delivery
      assert_equal ['padrino@me.com'],    email.from
      assert_equal ['padrino@you.com'],   email.to
      assert_equal 'Hello there Padrino', email.subject
      assert_equal 'Body',                email.body.to_s
    end

    it 'should send an basic email with body template' do
      mock_app do
        register Padrino::Mailer
        get "/" do
          email do
            views   File.dirname(__FILE__) + '/fixtures'
            from    'padrino@me.com'
            to      'padrino@you.com'
            subject 'Hello there Padrino'
            render  :basic
            via     :test
          end
        end
      end
      get "/"
      assert ok?
      email = pop_last_delivery
      assert_equal ['padrino@me.com'],    email.from
      assert_equal ['padrino@you.com'],   email.to
      assert_equal 'Hello there Padrino', email.subject
      assert_equal 'This is a body of text from a template with interpolated &lt;i&gt; and non-interpolated tags<br/>', email.body.to_s.chomp
    end

    it 'should send emails with scoped mailer defaults' do
      mock_app do
        register Padrino::Mailer
        set :views, File.dirname(__FILE__) + '/fixtures/views'
        set :delivery_method, :test
        mailer :alternate do
          defaults :from => 'padrino@from.com', :to => 'padrino@to.com'
          email :foo do
            to 'padrino@different.com'
            subject 'Hello there again Padrino'
            via     :test
            render  'alternate/foo'
          end
        end
        get("/") { deliver(:alternate, :foo) }
      end
      get "/"
      assert ok?
      email = pop_last_delivery
      assert_equal ['padrino@from.com'],    email.from, "should have used default value"
      assert_equal ['padrino@different.com'],   email.to, "should have overwritten default value"
      assert_equal 'Hello there again Padrino', email.subject
      assert_equal 'This is a foo message in mailers/alternate dir', email.body.to_s.chomp
    end

    it 'should send emails with app mailer defaults' do
      mock_app do
        register Padrino::Mailer
        set :delivery_method, :test
        set :views, File.dirname(__FILE__) + '/fixtures/views'
        set :mailer_defaults, :from => 'padrino@from.com', :to => 'padrino@to.com', :subject => "This is a test"
        mailer :alternate do
          email :foo do
            to 'padrino@different.com'
            via     :test
            render  'alternate/foo'
          end
        end
        get("/") { deliver(:alternate, :foo) }
      end
      get "/"
      assert ok?
      email = pop_last_delivery
      assert_equal ['padrino@from.com'],    email.from, "should have used default value"
      assert_equal ['padrino@different.com'],   email.to, "should have overwritten default value"
      assert_equal 'This is a test', email.subject
      assert_equal 'This is a foo message in mailers/alternate dir', email.body.to_s.chomp
    end

    it 'should send emails without layout' do
      mock_app do
        register Padrino::Mailer
        set :views, File.dirname(__FILE__) + '/fixtures/views'
        set :delivery_method, :test
        mailer :alternate do
          email :foo do
            from    'padrino@me.com'
            to      'padrino@you.com'
            subject 'Hello there Padrino'
            via     :test
            render  'alternate/foo'
          end
        end
        get("/") { deliver(:alternate, :foo) }
      end
      get "/"
      assert ok?
      email = pop_last_delivery
      assert_equal ['padrino@me.com'],    email.from
      assert_equal ['padrino@you.com'],   email.to
      assert_equal 'Hello there Padrino', email.subject
      assert_equal 'This is a foo message in mailers/alternate dir', email.body.to_s.chomp
      assert_match /TestMailer/, email.delivery_method.to_s
    end

    it 'should raise an error if there are two messages with the same name' do
      assert_raises RuntimeError do
        mock_app do
          register Padrino::Mailer
          mailer :foo do
            email :bar do; end
            email :bar do; end
          end
        end
      end
    end
  end
end
