require_relative 'helper'

# Reloading outside development needs tracking enabled before the apps load.
Padrino::Reloader.enabled = true
require_relative 'fixtures/apps/simple'

describe 'SimpleReloader' do
  describe 'for simple reset functionality' do
    it 'should reset routes' do
      mock_app do
        (1..10).each do |i|
          get("/#{i}") { "Foo #{i}" }
        end
      end

      (1..10).each do |i|
        get "/#{i}"
        assert_equal "Foo #{i}", body
      end

      @app.reset_routes!
      (1..10).each do |i|
        get "/#{i}"
        assert_equal 404, status
      end
    end

    it 'should keep sinatra routes on development' do
      mock_app do
        set :environment, :development
        get('/') { 'ok' }
      end

      assert_equal :development, @app.environment
      get '/'
      assert_equal 200, status
      get '/__sinatra__/404.png'
      assert_equal 200, status
      assert_match(%r{image/png}, response['Content-Type'])
      @app.reset_routes!
      get '/'
      assert_equal 404, status
      get '/__sinatra__/404.png'
      assert_equal 200, status
      assert_match(%r{image/png}, response['Content-Type'])
    end

    it 'should only serve its own images from the development sinatra route' do
      Dir.mktmpdir do |dir|
        File.binwrite("#{dir}/outside.png", 'not a padrino image')
        images = File.expand_path('../lib/padrino-core/images', __dir__)
        relative = Pathname.new("#{dir}/outside").relative_path_from(Pathname.new(images)).to_s
        mock_app do
          set :environment, :development
          get('/') { 'ok' }
        end
        get "/__sinatra__/#{relative.gsub('/', '%2F')}.png"
        refute_equal 'not a padrino image', body
        assert_equal 404, status
        get '/__sinatra__/0404.png'
        assert_equal 404, status
        get '/__sinatra__/500.png'
        assert_equal 200, status
      end
    end
  end

  describe 'for simple reload functionality' do
    before do
      Padrino.clear!
      Padrino.mount('simple_demo').to('/')
      Padrino.reload!
    end

    it 'should correctly instantiate SimpleDemo fixture' do
      assert_equal ['simple_demo'], Padrino.mounted_apps.map(&:name)
      assert SimpleDemo.reload?
      assert_match %r{fixtures/apps/simple.rb}, SimpleDemo.app_file
    end

    it 'should correctly reload SimpleDemo fixture' do
      @app = SimpleDemo
      get '/'
      assert ok?
      new_phrase = "The magick number is: #{rand(2**255)}!"
      buffer     = File.read(SimpleDemo.app_file)
      new_buffer = buffer.sub(/The magick number is: \d+!/, new_phrase)

      begin
        File.open(SimpleDemo.app_file, 'w') { |f| f.write(new_buffer) }
        Time.stub(:now, Time.now + 2) { get '/' }
        assert_equal new_phrase, body
      ensure
        File.open(SimpleDemo.app_file, 'w') { |f| f.write(buffer) }
        Padrino.reload!
      end
    end

    it 'should correctly reset SimpleDemo fixture' do
      @app = SimpleDemo
      get '/'
      @app.reload!
      get '/rand'
      assert ok?
      last_body = body
      assert_equal 1, @app.filters[:before].size
      assert_equal 0, @app.errors.reject { |key, _| [404, Sinatra::NotFound].include? key }.size
      assert_equal 2, @app.filters[:after].size # app + content-type + padrino-flash
      assert_equal 0, @app.middleware.size
      assert_equal 4, @app.routes.size # GET+HEAD of "/" + GET+HEAD of "/rand" = 4
      assert_equal 4, @app.extensions.size # [Padrino::ApplicationSetup, Padrino::ParamsProtection, Padrino::Routing, Padrino::Flash]
      assert_equal 0, @app.templates.size

      @app.reload!
      get '/rand'
      refute_equal last_body, body
      assert_equal 1, @app.filters[:before].size
      assert_equal 0, @app.errors.reject { |key, _| [404, Sinatra::NotFound].include? key }.size
      assert_equal 2, @app.filters[:after].size
      assert_equal 0, @app.middleware.size
      assert_equal 4, @app.routes.size # GET+HEAD of "/" = 2
      assert_equal 4, @app.extensions.size # [Padrino::ApplicationSetup, Padrino::ParamsProtection, Padrino::Routing, Padrino::Flash]
      assert_equal 0, @app.templates.size
    end
  end

  describe 'for excluded constants' do
    before do
      Object.const_set(:ExcludedPrefix, Class.new)
      ExcludedPrefix.const_set(:Inner, Class.new)
      Object.const_set(:ExcludedPrefixed, Class.new)
      Padrino::Reloader.exclude_constants << 'ExcludedPrefix'
    end

    after do
      Padrino::Reloader.exclude_constants.delete('ExcludedPrefix')
      Object.send(:remove_const, :ExcludedPrefix)
      Object.send(:remove_const, :ExcludedPrefixed)
    end

    it 'should exclude the constant and its namespace but not names sharing its prefix' do
      assert Padrino::Reloader.send(:constant_excluded?, ExcludedPrefix)
      assert Padrino::Reloader.send(:constant_excluded?, ExcludedPrefix::Inner)
      refute Padrino::Reloader.send(:constant_excluded?, ExcludedPrefixed)
    end

    it 'should accept symbols and classes as excluded constants' do
      Padrino::Reloader.exclude_constants.delete('ExcludedPrefix')
      [:ExcludedPrefix, ExcludedPrefix].each do |excluded|
        Padrino::Reloader.exclude_constants << excluded
        assert Padrino::Reloader.send(:constant_excluded?, ExcludedPrefix)
        assert Padrino::Reloader.send(:constant_excluded?, ExcludedPrefix::Inner)
        refute Padrino::Reloader.send(:constant_excluded?, ExcludedPrefixed)
        Padrino::Reloader.exclude_constants.delete(excluded)
      end
    end
  end

  describe 'for removing constants' do
    it 'should remove a namespaced constant without String inflections' do
      module ::ReloaderNamespace
        class Inner; end
      end

      without_string_inflections { Padrino::Reloader.remove_constant(ReloaderNamespace::Inner) }
      refute ReloaderNamespace.const_defined?(:Inner, false)
    ensure
      Object.send(:remove_const, :ReloaderNamespace)
    end
  end
end
