require_relative 'helper'
require 'open3'
require 'rbconfig'

describe 'Padrino::Auth' do
  it 'aliases AccessControlError to Auth::Error' do
    assert_same Padrino::Auth::Error, Padrino::Admin::AccessControlError
  end

  it 'checks rules without the admin' do
    rules = Padrino::Auth::Rules.new
    rules.roles_for(:any) { |a| a.protect '/secret'; a.allow '/open' }
    refute rules.allowed?(nil, '/secret')
    assert rules.allowed?(nil, '/open')
  end

  it 'gives a subclass of AccessControl::Base project_module' do
    klass = Class.new(Padrino::Admin::AccessControl::Base)
    rules = klass.new
    rules.roles_for(:any) { |a| a.project_module :foo, '/foo' }
    assert_equal '/foo', rules.project_modules(:any).first.path
  end

  it 'loads auth.rb without padrino-admin' do
    root = File.expand_path('../..', __dir__)
    libs = %w[padrino-core padrino-support padrino-admin].map { |gem| "-I#{File.join(root, gem, 'lib')}" }
    code = "require 'padrino-core'; require 'padrino-admin/auth'; p [defined?(Padrino::Admin), defined?(Padrino::Helpers), defined?(I18n)]"
    output, status = Open3.capture2e(RbConfig.ruby, *libs, '-e', code)
    assert status.success?, output
    assert_equal "[nil, nil, nil]\n", output
  end
end

describe 'register Padrino::Auth' do
  before { load_fixture 'sequel' }

  def auth_app(&block)
    @app = Sinatra.new(Padrino::Application) do
      register Padrino::Auth
      enable :sessions
      instance_eval(&block)
    end
  end

  it 'returns 401 on a protected path and 200 after login' do
    auth_app do
      access_control.roles_for(:any) { |a| a.protect '/'; a.allow '/login' }
      access_control.roles_for(:admin) { |a| a.allow '/' }
      get('/login') { set_current_account(Account.first); 'in' }
      get('/') { 'home' }
    end
    get '/'
    assert_equal 401, last_response.status
    assert_equal "You don't have permission for this resource", last_response.body
    get '/login'
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'home', last_response.body
  end

  it 'does not add admin view helpers' do
    auth_app { get('/') { 'x' } }
    instance = @app.new!
    refute_respond_to instance, :tag_icon
    refute_respond_to instance, :pat
  end

  it 'uses admin_model over account_model' do
    auth_app do
      set :admin_model, 'Nope'
      set :account_model, 'Account'
      access_control.roles_for(:any) { |a| a.protect '/' }
      get('/') { 'home' }
    end
    error = assert_raises(Padrino::Auth::Error) { get '/' }
    assert_match(/Nope/, error.message)
  end

  it 'keeps an admin_model_obj override' do
    @app = Sinatra.new(Padrino::Application) do
      register Padrino::Admin::AccessControl
      enable :sessions
      set :admin_model, 'Nope'
      helpers do
        def admin_model_obj
          Account
        end
      end
      access_control.roles_for(:any) { |a| a.protect '/'; a.allow '/login' }
      access_control.roles_for(:admin) { |a| a.allow '/' }
      get('/login') { set_current_account(Account.first); 'in' }
      get('/') { 'home' }
    end
    get '/login'
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'home', last_response.body
  end

  it 'accepts an admin_model without role, as before' do
    Object.const_set(:RolelessAdmin, Class.new do
      def self.find_by_id(id)
        new if id
      end

      def id
        1
      end
    end)
    @app = Sinatra.new(Padrino::Application) do
      register Padrino::Admin::AccessControl
      enable :sessions
      set :admin_model, 'RolelessAdmin'
      access_control.roles_for(:any) { |a| a.protect '/'; a.allow '/login' }
      get('/login') { set_current_account(RolelessAdmin.new); 'in' }
      get('/') { 'home' }
    end
    get '/login'
    get '/'
    assert_equal 200, last_response.status
  ensure
    Object.send(:remove_const, :RolelessAdmin) if defined?(RolelessAdmin)
  end

  it 'stores a mounted location' do
    auth_app do
      set :uri_root, '/api'
      enable :store_location
      set :login_page, '/login'
      access_control.roles_for(:any) { |a| a.protect '/posts' }
      get('/login') { set_current_account(Account.first); redirect_back_or_default('/default') }
      get('/posts') { 'posts' }
    end
    get '/posts?page=2', {}, 'SCRIPT_NAME' => '/api'
    assert_equal 302, last_response.status
    get '/login'
    assert_equal 'http://example.org/api/posts?page=2', last_response.location
  end
end

describe 'Padrino::Auth current_account_from' do
  before { load_fixture 'sequel' }

  def hook_app(hook = nil)
    Sinatra.new(Padrino::Application) do
      register Padrino::Auth
      set :raise_errors, true
      set :show_exceptions, false
      current_account_from(&hook) if hook
      access_control.roles_for(:any) { |a| a.protect '/'; a.allow '/login' }
      access_control.roles_for(:admin) { |a| a.allow '/' }
      get('/') { 'home' }
    end
  end

  it 'reads the account from a header token without sessions' do
    @app = hook_app(proc { Account.first if env['HTTP_AUTHORIZATION'] == 'Bearer t' })
    get '/'
    assert_equal 401, last_response.status
    get '/', {}, 'HTTP_AUTHORIZATION' => 'Bearer t'
    assert_equal 200, last_response.status
  end

  it 'never grants access for nil or false' do
    [proc { nil }, proc { false }].each do |hook|
      @app = hook_app(hook)
      get '/'
      assert_equal 401, last_response.status
    end
  end

  it 'raises for a result that is not an account' do
    @app = hook_app(proc { 'token' })
    error = assert_raises(Padrino::Auth::Error) { get '/' }
    assert_match(/current_account_from must return an account/, error.message)
  end

  it 'propagates hook errors' do
    @app = hook_app(proc { raise ArgumentError, 'boom' })
    assert_raises(ArgumentError) { get '/' }
  end

  it 'runs the hook once per request' do
    calls = 0
    @app = hook_app(proc { calls += 1; nil })
    get '/'
    assert_equal 401, last_response.status
    assert_equal 1, calls
  end

  it 'keeps hooks per app' do
    statuses = [proc { Account.first }, proc { nil }].map do |hook|
      Rack::MockRequest.new(hook_app(hook)).get('/').status
    end
    assert_equal [200, 401], statuses
  end
end

describe 'Padrino::Auth without a session' do
  before { load_fixture 'sequel' }

  def rules_app(&block)
    @app = Sinatra.new(Padrino::Application) do
      register Padrino::Auth
      access_control.roles_for(:any) { |a| a.protect '/'; a.allow '/login' }
      access_control.roles_for(:admin) { |a| a.allow '/' }
      instance_eval(&block) if block
    end
  end

  it 'warns once and returns 401 without a session' do
    rules_app { get('/') { 'home' } }
    _, err = capture_io do
      get '/'
      assert_equal 401, last_response.status
      get '/'
      assert_equal 401, last_response.status
    end
    assert_equal 1, err.scan('Padrino::Auth looks up').size
  end

  it 'uses session middleware when sessions? is false' do
    rules_app do
      use Rack::Session::Cookie, secret: 'x' * 64
      get('/login') { set_current_account(Account.first); 'in' }
      get('/') { 'home' }
    end
    _, err = capture_io do
      get '/login'
      get '/'
      assert_equal 200, last_response.status
    end
    refute_match(/Padrino::Auth looks up/, err)
  end
end

describe 'registering Padrino::Auth and AccessControl' do
  before { load_fixture 'sequel' }

  def any_authorizations(app)
    app.access_control.instance_variable_get(:@authorizations).count { |auth| auth.roles.include?(:any) }
  end

  it 'refuses AccessControl after Auth' do
    error = assert_raises(Padrino::Auth::Error) do
      Sinatra.new(Padrino::Application) do
        register Padrino::Auth
        register Padrino::Admin::AccessControl
      end
    end
    assert_equal 'Register Padrino::Admin::AccessControl instead of Padrino::Auth, not both', error.message
  end

  it 'keeps admin rules when Auth follows AccessControl' do
    counts = []
    @app = Sinatra.new(Padrino::Application) do
      register Padrino::Admin::AccessControl
      access_control.roles_for(:any) { |a| a.project_module :foo, '/foo' }
      counts << filters[:before].size
      register Padrino::Auth
      counts << filters[:before].size
    end
    assert_equal '/foo', @app.access_control.project_modules(:any).first.path
    assert_equal counts.first, counts.last
    assert_equal 1, @app.filters[:before].size
  end

  it 'is a no-op registered twice' do
    @app = Sinatra.new(Padrino::Application) do
      register Padrino::Auth
      enable :sessions
      access_control.roles_for(:any) { |a| a.protect '/' }
      register Padrino::Auth
      get('/') { 'home' }
    end
    get '/'
    assert_equal 401, last_response.status
    assert_equal 1, @app.filters[:before].size
  end

  [Padrino::Auth, Padrino::Admin::AccessControl].each do |extension|
    it "protects again after a reload with #{extension}" do
      file = proc do
        register extension
        enable :sessions
        access_control.roles_for(:any) { |a| a.protect '/' }
        get('/') { 'home' }
      end
      @app = Sinatra.new(Padrino::Application) { instance_eval(&file) }
      # What Padrino::Application#reload! does before it loads the app file again.
      @app.reset!
      @app.reset_router!
      @app.instance_eval(&file)
      get '/'
      assert_equal 401, last_response.status
      assert_equal 1, @app.filters[:before].size
      assert_equal 1, any_authorizations(@app)
    end
  end
end
