require_relative 'helper'

describe 'Host authorization' do
  before do
    skip 'needs Sinatra 4.1+' unless Sinatra::Base.respond_to?(:host_authorization)
    Padrino.clear!
  end

  def status_for(rack_app, host, path = '/')
    Rack::MockRequest.new(rack_app).get(path, 'HTTP_HOST' => host).status
  end

  describe 'when the app sets host_authorization' do
    it 'should answer permitted hosts and refuse others' do
      mock_app do
        set :host_authorization, permitted_hosts: ['good.example']
        get('/') { 'ok' }
      end
      assert_equal 200, status_for(@app, 'good.example')
      assert_equal 403, status_for(@app, 'evil.example')
    end

    it 'should apply it in development' do
      mock_app do
        set :environment, :development
        disable :reload
        set :host_authorization, permitted_hosts: ['good.example']
        get('/') { 'ok' }
      end
      assert_equal 200, status_for(@app, 'good.example')
      assert_equal 403, status_for(@app, 'evil.example')
    end

    it 'should apply a setting inherited from a parent app class' do
      parent = Sinatra.new(Padrino::Application) do
        set :host_authorization, permitted_hosts: ['good.example']
      end
      mock_app(parent) { get('/') { 'ok' } }
      assert_equal 200, status_for(@app, 'good.example')
      assert_equal 403, status_for(@app, 'evil.example')
    end

    it 'should apply a setting from Padrino.configure_apps' do
      Padrino.configure_apps { set :host_authorization, permitted_hosts: ['good.example'] }
      mock_app { get('/') { 'ok' } }
      assert_equal 200, status_for(@app, 'good.example')
      assert_equal 403, status_for(@app, 'evil.example')
    ensure
      Padrino.clear!
    end
  end

  describe 'when the app does not set host_authorization' do
    %i[development production test].each do |env|
      it "should answer any host in #{env}" do
        mock_app do
          set :environment, env
          disable :reload
          get('/') { 'ok' }
        end
        assert_equal 200, status_for(@app, 'myapp.example')
        assert_equal 200, status_for(@app, 'localhost')
      end
    end

    it 'should treat a setting that is not a Hash as unset' do
      mock_app do
        disable :host_authorization
        get('/') { 'ok' }
      end
      assert_equal 200, status_for(@app, 'myapp.example')
    end
  end

  describe 'for mounted apps' do
    before do
      Object.send(:remove_const, :HostAuthApp) if defined?(::HostAuthApp)
      ::HostAuthApp = Class.new(Padrino::Application) do
        set :host_authorization, permitted_hosts: ['good.example']
        get('/') { 'ok' }
      end
    end

    after do
      Object.send(:remove_const, :HostAuthApp)
      Padrino.clear!
    end

    it 'should apply it to an app mounted at the root' do
      Padrino.mount('HostAuthApp', app_file: __FILE__).to('/')
      assert_equal 200, status_for(Padrino.application, 'good.example')
      assert_equal 403, status_for(Padrino.application, 'evil.example')
    end

    it 'should apply it to an app mounted under a sub-path' do
      Padrino.mount('HostAuthApp', app_file: __FILE__).to('/sub')
      assert_equal 200, status_for(Padrino.application, 'good.example', '/sub')
      assert_equal 403, status_for(Padrino.application, 'evil.example', '/sub')
    end

    it 'should apply it to an app mounted for a host pattern' do
      Padrino.mount('HostAuthApp', app_file: __FILE__).host(/\.example\z/)
      assert_equal 200, status_for(Padrino.application, 'good.example')
      assert_equal 403, status_for(Padrino.application, 'evil.example')
    end

    it 'should leave a sibling app without the setting open to any host' do
      ::HostAuthOpenApp = Class.new(Padrino::Application) { get('/') { 'open' } }
      Padrino.mount('HostAuthApp', app_file: __FILE__).to('/locked')
      Padrino.mount('HostAuthOpenApp', app_file: __FILE__).to('/')
      assert_equal 403, status_for(Padrino.application, 'evil.example', '/locked')
      assert_equal 200, status_for(Padrino.application, 'evil.example', '/')
    ensure
      Object.send(:remove_const, :HostAuthOpenApp) if defined?(::HostAuthOpenApp)
    end
  end
end
