require File.expand_path(File.dirname(__FILE__) + '/helper')

describe Padrino::Flash do
  describe 'storage' do
    before do
      @storage = Padrino::Flash::Storage.new(
        :success => 'Success msg',
        :error   => 'Error msg',
        :notice  => 'Notice msg',
        :custom  => 'Custom msg'
      )
      @storage[:one] = 'One msg'
      @storage[:two] = 'Two msg'
    end

    it 'should acts like hash' do
      assert_respond_to @storage, :[]
    end

    it 'should know its size' do
      assert_equal 4, @storage.length
      assert_equal @storage.length, @storage.size
    end

    it 'should sweep its content' do
      assert_equal 2, @storage.sweep.size
      assert_empty @storage.sweep
    end

    it 'should discard everything' do
      assert_empty @storage.discard.sweep
    end

    it 'should discard specified key' do
      assert_equal 1, @storage.discard(:one).sweep.size
    end

    it 'should keep everything' do
      assert_equal 2, @storage.sweep.keep.sweep.size
    end

    it 'should keep only specified key' do
      assert_equal 1, @storage.sweep.keep(:one).sweep.size
    end

    it 'should not know the values you set right away' do
      @storage[:foo] = 'bar'
      refute_includes @storage, :foo
    end

    it 'should knows the values you set next time' do
      @storage[:foo] = 'bar'
      @storage.sweep
      assert_equal 'bar', @storage[:foo]
    end

    it 'should set values for now' do
      @storage.now[:foo] = 'bar'
      assert_equal 'bar', @storage[:foo]
    end

    it 'should forgets values you set only for now next time' do
      @storage.now[:foo] = 'bar'
      @storage.sweep
      refute_includes @storage, :foo
    end
  end

  routes = Proc.new do
    get :index do
      params[:key] ? flash[params[:key].to_sym].to_s : flash.now.inspect
    end

    post :index do
      params.each { |k,v| flash[k.to_sym] = v.to_s }
      flash.next.inspect
    end

    get :session do
      settings.sessions?.inspect
    end

    get :redirect do
      redirect url(:index, :key => :foo), 301, :foo => 'redirected!'
    end

    get :success do
      flash.success = 'Yup'
    end

    get :error do
      flash.error = 'Arg'
    end

    get :notice do
      flash.notice = 'Mmm'
    end
  end

  describe 'padrino application without sessions' do
    before { mock_app(&routes) }

    it 'should show nothing' do
      get '/'
      assert_equal '{}', body
    end

    it 'should set a flash' do
      post '/', :foo => :bar
      assert_equal '{:foo=>"bar"}', body
    end
  end

  describe 'padrino application with sessions' do
    before do
      mock_app { enable :sessions; class_eval(&routes) }
    end

    it 'should be sure have sessions enabled' do
      assert @app.sessions
      get '/session'
      assert_equal 'true', body
    end

    it 'should show nothing' do
      get '/'
      assert_equal '{}', body
    end

    it 'should set a flash' do
      post '/', :foo => :bar
      assert_equal '{:foo=>"bar"}', body
    end

    it 'should get a flash' do
      post '/', :foo => :bar
      get  '/', :key => :foo
      assert_equal 'bar', body
      post '/'
      assert_equal '{}', body
    end

    it 'should follow redirects with flash' do
      get '/redirect'
      follow_redirect!
      assert_equal 'redirected!', body
      assert 301, status
    end

    it 'should set success' do
      get '/success'
      get '/', :key => :success
      assert_equal 'Yup', body
    end

    it 'should set error' do
      get '/error'
      get '/', :key => :error
      assert_equal 'Arg', body
    end

    it 'should set notice' do
      get '/notice'
      get '/', :key => :notice
      assert_equal 'Mmm', body
    end
  end
end
