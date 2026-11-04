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
