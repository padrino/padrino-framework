require_relative 'helper'
require 'tmpdir'

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
      Object.send(:remove_const, :ExcludedPrefixed) if Object.const_defined?(:ExcludedPrefixed, false)
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

    it 'should go by the constant a class is named after when the class overrides name' do
      ExcludedPrefix::Inner.define_singleton_method(:name) { 'Elsewhere' }
      ExcludedPrefixed.define_singleton_method(:name) { 'ExcludedPrefix::Inner' }
      warned = Padrino.instance_variable_defined?(:@_orig_klass_name_warned)
      Padrino.remove_instance_variable(:@_orig_klass_name_warned) if warned
      _, err = capture_io do
        assert Padrino::Reloader.send(:constant_excluded?, ExcludedPrefix::Inner)
        Padrino::Reloader.remove_constant(ExcludedPrefixed)
      end
      refute Object.const_defined?(:ExcludedPrefixed, false)
      refute_includes err, '_orig_klass_name'
    ensure
      if warned
        Padrino.instance_variable_set(:@_orig_klass_name_warned, true)
      elsif Padrino.instance_variable_defined?(:@_orig_klass_name_warned)
        Padrino.remove_instance_variable(:@_orig_klass_name_warned)
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

    # Requires two classes from <tmp>/<folder>/located.rb and lets Reloader remove them, with the project at
    # <tmp>/app and <tmp>/<excluded_path> excluded. Returns the names of the ones it kept.
    def kept_constants_from(folder, excluded_path = nil)
      names = %i[ReloaderLocatedClass ReloaderLocatedError]
      tmp = Dir.mktmpdir
      excluded = File.join(tmp, excluded_path) if excluded_path
      Padrino::Reloader.exclude << excluded if excluded
      file = File.join(tmp, folder, 'located.rb')
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, <<-DOC)
        class ReloaderLocatedClass
          def self.value; end
        end

        class ReloaderLocatedError < StandardError
        end
      DOC
      require file
      Padrino.stub(:root, File.join(tmp, 'app')) do
        names.each { |name| Padrino::Reloader.remove_constant(Object.const_get(name)) }
      end
      names.select { |name| Object.const_defined?(name, false) }
    ensure
      Padrino::Reloader.exclude.delete(excluded)
      $LOADED_FEATURES.delete(file)
      names.each { |name| Object.send(:remove_const, name) if Object.const_defined?(name, false) }
      FileUtils.rm_rf(tmp)
    end

    it 'should keep constants defined in an excluded folder' do
      assert_equal %i[ReloaderLocatedClass ReloaderLocatedError], kept_constants_from('app/config', 'app/config')
    end

    it 'should keep constants defined in an excluded file' do
      assert_equal %i[ReloaderLocatedClass ReloaderLocatedError], kept_constants_from('app/lib', 'app/lib/located.rb')
    end

    it 'should remove constants defined in a folder whose name only starts with an excluded one' do
      assert_empty kept_constants_from('app/configuration', 'app/config')
    end

    it 'should keep constants defined in a folder next to the project that shares its name as a prefix' do
      assert_equal %i[ReloaderLocatedClass ReloaderLocatedError], kept_constants_from('app-other')
    end

    it 'should remove constants defined in the project folder' do
      assert_empty kept_constants_from('app')
    end

    it 'should not track files in a folder next to the project that shares its name as a prefix' do
      Padrino.stub(:root, '/srv/app') do
        assert Padrino::Reloader.send(:feature_excluded?, '/srv/app-gems/lib/located.rb')
        refute Padrino::Reloader.send(:feature_excluded?, '/srv/app/lib/located.rb')
      end
    end

    it 'should remove a class that overrides to_s by the constant it is named after' do
      module ::ReloaderNamespace
        class Disguised
          def self.to_s
            'SomethingElse'
          end
        end
      end

      Padrino::Reloader.remove_constant(ReloaderNamespace::Disguised)
      refute ReloaderNamespace.const_defined?(:Disguised, false)
    ensure
      Object.send(:remove_const, :ReloaderNamespace)
    end
  end
end
