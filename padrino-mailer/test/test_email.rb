require_relative 'helper'

describe 'Email' do
  describe 'the mailer in an app' do
    it 'should send a basic inline email' do
      mock_app do
        register Padrino::Mailer
        get '/' do
          email do
            from    'padrino@me.com'
            to      'padrino@you.com'
            subject 'Hello there Padrino'
            body    'Body'
            via     :test
          end
        end
      end
      get '/'
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
        get '/' do
          email(
            from: 'padrino@me.com',
            to: 'padrino@you.com',
            subject: 'Hello there Padrino',
            body: 'Body',
            via: :test
          )
        end
      end
      get '/'
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
        get '/' do
          email do
            views   "#{__dir__}/fixtures"
            from    'padrino@me.com'
            to      'padrino@you.com'
            subject 'Hello there Padrino'
            render  :basic
            via     :test
          end
        end
      end
      get '/'
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
        set :views, "#{__dir__}/fixtures/views"
        set :delivery_method, :test
        mailer :alternate do
          defaults from: 'padrino@from.com', to: 'padrino@to.com'
          email :foo do
            to 'padrino@different.com'
            subject 'Hello there again Padrino'
            via     :test
            render  'alternate/foo'
          end
        end
        get('/') { deliver(:alternate, :foo) }
      end

      get '/'
      assert ok?
      email = pop_last_delivery
      assert_equal ['padrino@from.com'], email.from, 'should have used default value'
      assert_equal ['padrino@different.com'], email.to, 'should have overwritten default value'
      assert_equal 'Hello there again Padrino', email.subject
      assert_equal 'This is a foo message in mailers/alternate dir', email.body.to_s.chomp
    end

    it 'should send emails with app mailer defaults' do
      mock_app do
        register Padrino::Mailer
        set :delivery_method, :test
        set :views, "#{__dir__}/fixtures/views"
        set :mailer_defaults, from: 'padrino@from.com', to: 'padrino@to.com', subject: 'This is a test'
        mailer :alternate do
          email :foo do
            to 'padrino@different.com'
            via     :test
            render  'alternate/foo'
          end
        end
        get('/') { deliver(:alternate, :foo) }
      end

      get '/'
      assert ok?
      email = pop_last_delivery
      assert_equal ['padrino@from.com'], email.from, 'should have used default value'
      assert_equal ['padrino@different.com'], email.to, 'should have overwritten default value'
      assert_equal 'This is a test', email.subject
      assert_equal 'This is a foo message in mailers/alternate dir', email.body.to_s.chomp
    end

    it 'should send emails without layout' do
      mock_app do
        register Padrino::Mailer
        set :views, "#{__dir__}/fixtures/views"
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
        get('/') { deliver(:alternate, :foo) }
      end
      get '/'
      assert ok?
      email = pop_last_delivery
      assert_equal ['padrino@me.com'],    email.from
      assert_equal ['padrino@you.com'],   email.to
      assert_equal 'Hello there Padrino', email.subject
      assert_equal 'This is a foo message in mailers/alternate dir', email.body.to_s.chomp
      assert_match(/TestMailer/, email.delivery_method.to_s)
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

  describe 'the mailer views path' do
    def mailer_views(root)
      views = File.join(@tmp, root, 'views')
      { 'alpha/hello.erb' => 'alpha hello', 'beta/hello.erb' => 'beta hello',
        'gamma/hello.plain.erb' => 'gamma plain', 'gamma/hello.html.erb' => 'gamma html' }.each do |path, content|
        file = File.join(views, 'mailers', path)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, content)
      end
      views
    end

    def mailer_app(views)
      mock_app do
        register Padrino::Mailer
        set :views, views
        set :delivery_method, :test
        set :mailer_defaults, from: 'padrino@me.com', to: 'padrino@you.com'
        mailer(:alpha) { email(:hello) { via :test; render :hello } }
        mailer(:beta)  { email(:hello) { via :test; render :hello } }
        mailer(:gamma) { email(:hello) { via :test; provides :plain, :html; render :hello } }
      end
    end

    def build_message(mailer_name)
      message = @app.settings._padrino_mailer::Message.new(@app)
      message.mailer_name = mailer_name
      message
    end

    before { @tmp = Dir.mktmpdir }
    after  { FileUtils.rm_rf(@tmp) }

    it 'should add the mailer name when the app path contains it' do
      mailer_app(mailer_views('beta_site'))
      email = @app.deliver(:beta, :hello)
      assert_equal 'beta hello', email.body.to_s
    end

    it 'should not leak the mailer path between messages' do
      mailer_app(mailer_views('site'))
      alpha = build_message(:alpha)
      beta = build_message(:beta)
      assert_equal 'beta hello', beta.send(:render, :hello)
      assert_equal 'alpha hello', alpha.send(:render, :hello)
    end

    it 'should not reuse a cached template from another mailer' do
      views = mailer_views('site')
      File.write(File.join(views, 'mailers', 'beta', 'greet.haml'), '%p beta greet')
      File.write(File.join(views, 'mailers', 'alpha', 'greet.erb'), 'alpha greet')
      mailer_app(views)
      @app.set :reload_templates, false
      @app.mailer(:alpha) { email(:greet) { via :test; render :greet } }
      @app.mailer(:beta)  { email(:greet) { via :test; render :greet } }
      assert_equal 'alpha greet', @app.deliver(:alpha, :greet).body.to_s
      assert_equal '<p>beta greet</p>', @app.deliver(:beta, :greet).body.to_s.strip
    end

    it 'should render a partial from a mailer template' do
      views = mailer_views('site')
      File.write(File.join(views, 'mailers', 'alpha', 'listing.erb'), "<%= partial 'item', object: 'one' %>")
      File.write(File.join(views, 'mailers', 'alpha', '_item.erb'), 'item <%= item %>')
      mailer_app(views)
      @app.mailer(:alpha) { email(:listing) { via :test; render :listing } }
      assert_equal 'item one', @app.deliver(:alpha, :listing).body.to_s.strip
    end

    it 'should render the message template with options when the engine is nil' do
      views = mailer_views('site')
      File.write(File.join(views, 'mailers', 'alpha', 'boxed.erb'), 'boxed')
      File.write(File.join(views, 'mailers', 'alpha', 'box.erb'), '[<%= yield %>]')
      mailer_app(views)
      @app.mailer(:alpha) { email(:boxed) { via :test; render nil, layout: :box } }
      assert_equal '[boxed]', @app.deliver(:alpha, :boxed).body.to_s.strip
    end

    it 'should not add a part per partial to a message with an attachment' do
      views = mailer_views('site')
      File.write(File.join(views, 'mailers', 'alpha', 'listing.erb'), "<%= partial 'item', collection: %w[a b] %>")
      File.write(File.join(views, 'mailers', 'alpha', '_item.erb'), '<%= item %>')
      mailer_app(views)
      @app.mailer(:alpha) { email(:listing) { via :test; add_file filename: 'a.txt', content: 'file'; render :listing } }
      email = @app.deliver(:alpha, :listing)
      assert_equal(%w[ab file], email.parts.map { |part| part.body.to_s.strip })
    end

    it 'should not reuse a cached layout from another mailer' do
      views = mailer_views('site')
      File.write(File.join(views, 'mailers', 'alpha', 'box.erb'), 'A[<%= yield %>]')
      FileUtils.mkdir_p(File.join(views, 'mailers', 'beta', 'layouts'))
      File.write(File.join(views, 'mailers', 'beta', 'layouts', 'box.erb'), 'B[<%= yield %>]')
      mailer_app(views)
      @app.set :reload_templates, false
      @app.mailer(:alpha) { email(:boxed) { via :test; render :hello, layout: :box } }
      @app.mailer(:beta)  { email(:boxed) { via :test; render :hello, layout: :box } }
      assert_equal 'A[alpha hello]', @app.deliver(:alpha, :boxed).body.to_s.strip
      assert_equal 'B[beta hello]', @app.deliver(:beta, :boxed).body.to_s.strip
    end

    MailerFormUser = Struct.new(:name) unless defined?(MailerFormUser)

    it 'should build forms with form_for in a mailer template' do
      views = mailer_views('site')
      File.write(File.join(views, 'mailers', 'alpha', 'signup.erb'), "<% @user = MailerFormUser.new('Joe') %><%= form_for(:user, '/signup') { |f| f.text_field(:name) } %>")
      mailer_app(views)
      @app.mailer(:alpha) { email(:signup) { via :test; render :signup } }
      body = @app.deliver(:alpha, :signup).body.to_s
      assert_match(%r{<form[^>]*action="/signup"}, body)
      assert_match(/<input type="text" name="mailer_form_user\[name\]" value="Joe"/, body)
    end

    it 'should build forms in a mailer template without a CSRF token' do
      views = mailer_views('site')
      File.write(File.join(views, 'mailers', 'alpha', 'confirm.erb'), "<%= button_to 'Confirm', '/confirm' %>")
      mailer_app(views)
      @app.mailer(:alpha) { email(:confirm) { via :test; render :confirm } }
      body = @app.deliver(:alpha, :confirm).body.to_s
      assert_match(%r{<form[^>]*action="/confirm"}, body)
      refute_match(/authenticity_token/, body)
    end

    it 'should render each provided format from the mailer path' do
      mailer_app(mailer_views('site'))
      email = @app.deliver(:gamma, :hello)
      assert_equal(['gamma plain', 'gamma html'], email.parts.map { |part| part.body.to_s })
    end
  end
end
