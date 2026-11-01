require_relative 'helper'

describe 'AdminApplication' do
  def setup
    load_fixture 'sequel'
  end

  describe 'session id setting' do
    it "should provide it if it doesn't exist" do
      mock_app do
        set :app_name, 'session_id_tester'
        register Padrino::Admin::AccessControl
      end

      assert_equal '_padrino_test_session_id_tester', @app.session_id
    end

    it 'should preserve it if it already existed' do
      mock_app do
        set :session_id, 'foo'
        register Padrino::Admin::AccessControl
      end
      assert_equal 'foo', @app.session_id
    end
  end

  it 'should require correctly login' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      # Do a simple mapping
      access_control.roles_for :any do |role|
        role.protect '/foo'
      end

      get '/foo', provides: %i[html js] do
        'foo'
      end

      get '/unauthenticated' do
        'unauthenticated'
      end
    end

    get '/foo'
    assert_equal "You don't have permission for this resource", body

    get '/unauthenticated'
    assert_equal 'unauthenticated', body
  end

  it 'should set basic roles with store location and login page' do
    mock_app do
      set    :app_name, :basic_app
      register Padrino::Admin::AccessControl
      enable :store_location
      enable :sessions
      set    :login_page, '/login'

      access_control.roles_for :any do |role|
        role.protect '/foo'
      end

      # Prepare a basic page
      get '/login' do
        redirect_back_or_default('/foo') if logged_in?
        set_current_account(Account.admin)
        'login page'
      end

      get '/foo' do
        'foo'
      end
    end

    get '/foo'
    follow_redirect!
    assert_equal 'login page', body

    get '/foo'
    assert_equal 'foo', body

    get '/login'
    follow_redirect!
    assert_equal 'foo', body
  end

  describe 'sessions' do
    def mock_session_app(store)
      mock_app do
        register Padrino::Admin::AccessControl
        set :session_store, store
        enable :sessions

        get('/note') { session[:note] = 'kept'; session[:return_to] = '/posts'; session.id.to_s }
        get('/login/:role') { set_current_account(Account.send(params[:role])); 'logged in' }
        get('/logout') { set_current_account(nil); 'logged out' }
        get '/state' do
          [session.id.to_s, session[:note].inspect, session[:return_to].inspect, session.key?(settings.session_id), logged_in?].join(' ')
        end
      end
    end

    def session_state
      get '/state'
      %i[id note return_to account_key logged_in].zip(body.split).to_h
    end

    [Rack::Session::Cookie, Rack::Session::Pool].each do |store|
      it "should start a new session at login with #{store.name}, keeping its data" do
        mock_session_app(store)
        get '/note'
        before_login = body
        cookie = current_session.cookie_jar['rack.session']

        get '/login/admin'
        state = session_state
        refute_equal before_login, state[:id]
        refute_equal cookie, current_session.cookie_jar['rack.session']
        assert_equal '"kept"', state[:note]
        assert_equal 'true', state[:logged_in]
      end

      it "should start a new session when the account changes, not when it is set again, with #{store.name}" do
        mock_session_app(store)
        get '/login/admin'
        logged_in_id = session_state[:id]

        get '/login/admin'
        assert_equal logged_in_id, session_state[:id]

        get '/login/editor'
        refute_equal logged_in_id, session_state[:id]
      end

      it "should remove only the account from the session at logout and start a new one with #{store.name}" do
        mock_session_app(store)
        get '/note'
        get '/login/admin'
        logged_in_id = session_state[:id]

        get '/logout'
        state = session_state
        assert_equal 'false', state[:account_key]
        assert_equal 'false', state[:logged_in]
        assert_equal '"kept"', state[:note]
        assert_equal '"/posts"', state[:return_to]
        refute_equal logged_in_id, state[:id]
      end

      it "should leave the session alone when nobody was logged in with #{store.name}" do
        mock_session_app(store)
        get '/note'
        before = session_state

        get '/logout'
        assert_equal before, session_state
        assert_equal '"/posts"', before[:return_to]
      end
    end
  end

  describe 'CSRF token' do
    before do
      mock_app do
        register Padrino::Admin::AccessControl
        enable :sessions
        set :protect_from_csrf, true

        get('/form') { csrf_token }
        post('/login') { set_current_account(Account.admin); 'logged in' }
        post('/login-and-form') { set_current_account(Account.admin); csrf_token }
        post('/logout') { set_current_account(nil); 'logged out' }
        post('/action') { 'done' }
      end
    end

    it 'should reject a token issued before login and accept one issued after' do
      get '/form'
      token = body
      post '/login', authenticity_token: token
      assert_equal 200, status

      post '/action', authenticity_token: token
      assert_equal 403, status

      get '/form'
      post '/action', authenticity_token: body
      assert_equal 200, status
    end

    it 'should accept a token rendered in the request that logs in' do
      get '/form'
      post '/login-and-form', authenticity_token: body
      post '/action', authenticity_token: body
      assert_equal 200, status
    end

    it 'should keep the token when nobody was logged in' do
      get '/form'
      token = body
      post '/logout', authenticity_token: token
      post '/action', authenticity_token: token
      assert_equal 200, status
    end
  end

  describe 'redirect_back_or_default' do
    def mock_redirect_app(absolute_redirects)
      mock_app do
        register Padrino::Admin::AccessControl
        enable :sessions
        set :absolute_redirects, absolute_redirects
        get('/remember') { session[:return_to] = params[:to]; 'remembered' }
        get('/back') { redirect_back_or_default('/default') }
      end
    end

    def redirect_back_from(return_to)
      get '/remember', to: return_to
      get '/back'
      last_response.location
    end

    { true => 'http://example.org/default', false => '/default' }.each do |absolute_redirects, default|
      it "should redirect back to a local path (absolute_redirects: #{absolute_redirects})" do
        mock_redirect_app(absolute_redirects)
        base = default.delete_suffix('/default')
        assert_equal "#{base}/posts?page=2&q=a%2Fb", redirect_back_from('/posts?page=2&q=a%2Fb')
        assert_equal "#{base}/caf%C3%A9/1", redirect_back_from('/caf%C3%A9/1')
      end

      it "should redirect to the default for anything but a local path (absolute_redirects: #{absolute_redirects})" do
        mock_redirect_app(absolute_redirects)
        ['//example.com', '///example.com', '/\\example.com', "/\t/example.com", '/%2F%2Fexample.com', '/%2f/example.com',
         '/%5Cexample.com', '/%09/example.com', 'https://example.com', 'https://example.com/posts', 'javascript:alert(1)',
         'example.com', '', "/\xff".dup.force_encoding('UTF-8')].each do |return_to|
          assert_equal default, redirect_back_from(return_to), return_to.inspect
        end
      end
    end

    it 'should redirect to the default without a stored location' do
      mock_redirect_app(true)
      get '/back'
      assert_equal 'http://example.org/default', last_response.location
    end
  end

  it 'should store the location under RACK_BASE_URI and redirect back to it after login' do
    saved_base_uri = ENV['RACK_BASE_URI']
    mock_app do
      register Padrino::Admin::AccessControl
      enable :store_location
      enable :sessions
      set :login_page, '/login'

      access_control.roles_for :any do |role|
        role.protect '/foo'
      end

      get('/login') { set_current_account(Account.admin); redirect_back_or_default('/default') }
      get('/foo') { 'foo' }
    end

    { nil => 'http://example.org/foo?x=1', '/base' => 'http://example.org/base/foo?x=1', '/' => 'http://example.org/foo?x=1' }.each do |base_uri, location|
      ENV['RACK_BASE_URI'] = base_uri
      # WEBrick sets REQUEST_URI to the full URL, puma to the path.
      ['/foo?x=1', 'http://example.org/foo?x=1'].each do |request_uri|
        clear_cookies
        get '/foo?x=1', {}, 'REQUEST_URI' => request_uri
        assert_equal 302, status
        get '/login'
        assert_equal location, last_response.location, "RACK_BASE_URI=#{base_uri.inspect}, REQUEST_URI=#{request_uri}"
      end
    end
  ensure
    ENV['RACK_BASE_URI'] = saved_base_uri
  end

  it 'should answer 401 to visitors and 403 to accounts without access when there is no login page' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.protect '/'
        role.allow '/login'
      end

      access_control.roles_for :editor do |role|
        role.project_module :posts, '/posts'
      end

      access_control.roles_for :admin do |role|
        role.project_module :settings, '/settings'
      end

      get('/login/:role') { set_current_account(Account.send(params[:role])); 'logged in' }
      get('/settings') { 'settings' }
    end

    get '/settings'
    assert_equal 401, status

    get '/login/editor'
    get '/settings'
    assert_equal 403, status
    assert_equal "You don't have permission for this resource", body
  end

  it 'should set advanced roles with store location and login page' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.protect '/'
        role.allow '/login'
        role.allow '/any'
      end

      access_control.roles_for :admin do |role|
        role.project_module :settings, '/settings'
      end

      access_control.roles_for :editor do |role|
        role.project_module :posts, '/posts'
      end

      # Prepare a basic page
      get '/login(/:role)?' do
        set_current_account(Account.send(params[:role])) if params[:role]
        "logged as #{params[:role] || 'any'}"
      end

      get '/any'      do; 'any';      end
      get '/settings' do; 'settings'; end
      get '/posts'    do; 'posts';    end
    end

    assert @app.access_control.allowed?(Account.admin, '/login')
    assert @app.access_control.allowed?(Account.admin, '/any')
    assert @app.access_control.allowed?(Account.admin, '/settings')
    refute @app.access_control.allowed?(Account.admin, '/posts')

    assert @app.access_control.allowed?(Account.editor, '/login')
    assert @app.access_control.allowed?(Account.editor, '/any')
    refute @app.access_control.allowed?(Account.editor, '/settings')
    assert @app.access_control.allowed?(Account.editor, '/posts')

    get '/login'
    assert_equal 'logged as any', body

    get '/any'
    assert_equal 'any', body

    get '/settings'
    assert_equal "You don't have permission for this resource", body

    get '/posts'
    assert_equal "You don't have permission for this resource", body

    get '/login/admin'
    assert_equal 'logged as admin', body

    get '/any'
    assert_equal 'any', body

    get '/settings'
    assert_equal 'settings', body

    get '/posts'
    assert_equal "You don't have permission for this resource", body

    get '/login/editor'
    assert_equal 'logged as editor', body

    get '/any'
    assert_equal 'any', body

    get '/settings'
    assert_equal "You don't have permission for this resource", body

    get '/posts'
    assert_equal 'posts', body
  end

  it 'should match paths literally without regex metacharacter interpretation' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.protect '/'
        role.allow '/accounts.json'
      end
    end

    # Without authentication, /accounts.json should be allowed
    assert @app.access_control.allowed?(nil, '/accounts.json')
    # /accountsXjson must NOT match - the dot in .json is literal, not a regex wildcard
    refute @app.access_control.allowed?(nil, '/accountsXjson')
  end

  it 'should not allow paths that merely start with an allowed path' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.protect '/'
        role.allow '/sessions'
      end

      access_control.roles_for :editor do |role|
        role.project_module :posts, '/posts'
      end

      access_control.roles_for :admin do |role|
        role.project_module :post_admin, '/posts_admin'
      end
    end

    assert @app.access_control.allowed?(nil, '/sessions')
    assert @app.access_control.allowed?(nil, '/sessions/new')
    assert @app.access_control.allowed?(nil, '/sessions.json')
    refute @app.access_control.allowed?(nil, '/sessions_admin')
    refute @app.access_control.allowed?(nil, '/sessionsX')

    # An editor's '/posts' must not reach the admin-only '/posts_admin' module.
    assert @app.access_control.allowed?(Account.editor, '/posts')
    assert @app.access_control.allowed?(Account.editor, '/posts/1/edit')
    refute @app.access_control.allowed?(Account.editor, '/posts_admin')
    assert @app.access_control.allowed?(Account.admin, '/posts_admin')

    # Paths are compared after percent-decoding.
    refute @app.access_control.allowed?(Account.editor, '/%70osts_admin')
    assert @app.access_control.allowed?(Account.editor, '/%70osts')
  end

  it 'should allow decoded non-ASCII paths and prefixes ending in a dot' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.protect '/'
        role.allow '/café'
        role.allow '/v1.'
      end
    end

    assert @app.access_control.allowed?(nil, '/caf%C3%A9'.b)
    assert @app.access_control.allowed?(nil, '/café')
    assert @app.access_control.allowed?(nil, '/v1.json')
    refute @app.access_control.allowed?(nil, '/v2.json')
  end

  it 'should match Regexp paths at the start of the path' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.protect %r{\A/secret}
        role.allow %r{\A/reports/\d+\z}
      end

      access_control.roles_for :admin do |role|
        role.allow %r{\A/stats}
        role.project_module :posts, '/posts'
      end
    end

    assert @app.access_control.allowed?(nil, '/reports/1')
    refute @app.access_control.allowed?(nil, '/secret/x')
    assert @app.access_control.allowed?(Account.admin, '/stats/today')
    assert @app.access_control.allowed?(Account.admin, '/posts')
    refute @app.access_control.allowed?(Account.editor, '/stats')
  end

  it 'should check paths that are not valid UTF-8 once decoded' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.protect %r{\A/secret}
        role.protect '/reports'
        role.allow %r{\A/reports/\d+\z}
      end
    end

    refute @app.access_control.allowed?(nil, '/secret%ff')
    refute @app.access_control.allowed?(nil, '/reports/%c0%ae')
    assert @app.access_control.allowed?(nil, '/reports/1')
    assert @app.access_control.allowed?(nil, '/public/%ff')
  end

  it 'should emulate an ecommerce app' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.protect '/cart'
        role.allow '/cart/add'
        role.allow '/cart/empty'
      end

      get '/login' do
        set_current_account(Account.admin)
        'Logged in'
      end

      get '/cart/checkout' do
        'Checkout'
      end

      get '/cart/add' do
        'Product Added'
      end

      get '/cart/empty' do
        'Cart Empty'
      end
    end

    get '/cart/checkout'
    assert_equal "You don't have permission for this resource", body

    get '/cart/add'
    assert_equal 'Product Added', body

    get '/cart/empty'
    assert_equal 'Cart Empty', body

    get '/login'
    assert_equal 'Logged in', body

    get '/cart/checkout'
    assert_equal 'Checkout', body

    get '/cart/add'
    assert_equal 'Product Added', body

    get '/cart/empty'
    assert_equal 'Cart Empty', body
  end

  it 'should check access control helper' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.project_module :foo, '/foo'
        role.project_module :bar, '/bar'
      end

      access_control.roles_for :admin do |role|
        role.project_module :admin, '/admin'
      end

      access_control.roles_for :editor do |role|
        role.project_module :editor, '/editor'
      end

      get '/login' do
        set_current_account(Account.admin)
        'Logged in'
      end

      get '/roles' do
        access_control.roles.join(', ')
      end

      get '/modules' do
        project_modules.map { |pm| "#{pm.name} => #{pm.path}" }.join(', ')
      end

      get '/modules-prefixed' do
        project_modules.map { |pm| "#{pm.name} => #{pm.path('/admin')}" }.join(', ')
      end
    end

    get '/roles'
    assert_equal 'admin, editor', body

    get '/modules'
    assert_equal 'foo => /foo, bar => /bar', body

    get '/modules-prefixed'
    assert_equal 'foo => /admin/foo, bar => /admin/bar', body

    get '/login'
    assert_equal 'Logged in', body

    get '/modules'
    assert_equal 'admin => /admin', body
  end

  it 'should use different access control for different apps' do
    app1 = Sinatra.new Padrino::Application do
      register Padrino::Admin::AccessControl
      access_control.roles_for :any do |role|
        role.project_module :foo, '/foo'
      end
    end
    app2 = Sinatra.new Padrino::Application do
      register Padrino::Admin::AccessControl
      access_control.roles_for :any do |role|
        role.project_module :bar, '/bar'
      end
    end
    assert_equal '/foo', app1.access_control.project_modules(:any).first.path
    assert_equal '/bar', app2.access_control.project_modules(:any).first.path
  end

  it 'should raise AccessControlError for invalid roles' do
    access_control = Padrino::Admin::AccessControl::Base.new
    error = assert_raises(Padrino::Admin::AccessControlError) { access_control.roles_for('admin') }
    assert_match(/"admin"/, error.message)
    assert_raises(Padrino::Admin::AccessControlError) { access_control.roles_for }
  end

  describe 'admin model' do
    def mock_admin_app(admin_model)
      mock_app do
        register Padrino::Admin::AccessControl
        set :admin_model, admin_model
        get('/current') { current_account.inspect }
      end
    end

    it 'should say a missing admin model must be defined' do
      mock_admin_app 'MissingAdminSample::Account'
      error = assert_raises(Padrino::Admin::AccessControlError) { get '/current' }
      assert_equal 'You must define an MissingAdminSample::Account Model', error.message
    end

    it 'should say a missing admin model must be defined when its name repeats a namespace' do
      Object.const_set(:RepeatedAdminSample, Module.new)
      mock_admin_app 'RepeatedAdminSample::RepeatedAdminSample'
      error = assert_raises(Padrino::Admin::AccessControlError) { get '/current' }
      assert_equal 'You must define an RepeatedAdminSample::RepeatedAdminSample Model', error.message
    ensure
      Object.send(:remove_const, :RepeatedAdminSample) if Object.const_defined?(:RepeatedAdminSample, false)
    end

    it 'should raise the error of a top-level admin model whose body names another constant like it' do
      Dir.mktmpdir do |dir|
        File.write("#{dir}/colliding_top_account.rb", <<~RUBY)
          module CollidingTopMixins; end
          class CollidingTopAccount
            include CollidingTopMixins::CollidingTopAccount
          end
        RUBY
        Object.autoload(:CollidingTopAccount, "#{dir}/colliding_top_account.rb")
        mock_admin_app 'CollidingTopAccount'
        error = assert_raises(NameError) { get '/current' }
        assert_match(/CollidingTopMixins::CollidingTopAccount/, error.message)
      end
    ensure
      %i[CollidingTopAccount CollidingTopMixins].each { |name| Object.send(:remove_const, name) if Object.const_defined?(name, false) }
    end

    it 'should raise the error of an admin model whose body names another constant like it' do
      Dir.mktmpdir do |dir|
        File.write("#{dir}/colliding_admin_sample.rb", <<~RUBY)
          module CollidingAdminSample
            module Mixins; end
            class Account
              include Mixins::Account
            end
          end
        RUBY
        Object.autoload(:CollidingAdminSample, "#{dir}/colliding_admin_sample.rb")
        mock_admin_app 'CollidingAdminSample::Account'
        error = assert_raises(NameError) { get '/current' }
        assert_match(/Mixins::Account/, error.message)
      end
    ensure
      Object.send(:remove_const, :CollidingAdminSample) if Object.const_defined?(:CollidingAdminSample, false)
    end

    it 'should raise the error of an admin model that fails to load' do
      Dir.mktmpdir do |dir|
        File.write("#{dir}/broken_admin_sample.rb", "module BrokenAdminSample; class Account; MissingConcern; end; end\n")
        Object.autoload(:BrokenAdminSample, "#{dir}/broken_admin_sample.rb")
        mock_admin_app 'BrokenAdminSample::Account'
        error = assert_raises(NameError) { get '/current' }
        assert_match(/MissingConcern/, error.message)
      end
    ensure
      Object.send(:remove_const, :BrokenAdminSample) if Object.const_defined?(:BrokenAdminSample, false)
    end
  end

  it 'should humanize project module names without ActiveSupport' do
    assert_equal 'Blog posts', Padrino::Admin::AccessControl::ProjectModule.new(:blog_posts, '/blog_posts').human_name
  end
end
