require_relative 'helper'

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

  describe 'for classes with methods not written in Ruby' do
    before do
      @dir = Dir.mktmpdir('native', Padrino.root)
      @constants = []
    end

    after do
      Dir.glob("#{@dir}/**/*.rb").each do |file|
        Padrino::Reloader::Storage.remove(file)
        Padrino::Reloader::MTIMES.delete(file)
        $LOADED_FEATURES.delete(file)
      end
      @constants.each { |name| Object.send(:remove_const, name) if Object.const_defined?(name, false) }
      FileUtils.rm_rf(@dir)
    end

    def write(path, source)
      file = "#{@dir}/#{path}"
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, source)
      file
    end

    it 'should unload the Struct, Data and aliasing classes of a project file it reloads' do
      @constants.concat(%i[ReloaderPoint ReloaderShape ReloaderLabeled])
      file = write('models/native.rb', <<-RUBY)
        ReloaderPoint = Struct.new(:x, :y) do
          def sum
            x + y
          end
        end
        ReloaderShape = Data.define(:width) if #{RUBY_VERSION >= '3.2'}
        class ReloaderLabeled
          alias label inspect
          def removed; end
        end
      RUBY
      Padrino::Reloader.safe_load(file)
      assert_equal 3, ReloaderPoint.new(1, 2).sum

      File.write(file, "class ReloaderLabeled\n  alias label inspect\nend\n")
      Padrino::Reloader.safe_load(file, force: true)
      refute Object.const_defined?(:ReloaderPoint, false), 'ReloaderPoint was not removed'
      refute Object.const_defined?(:ReloaderShape, false), 'ReloaderShape was not removed'
      refute ReloaderLabeled.method_defined?(:removed), 'ReloaderLabeled was not reloaded'
    end

    it 'should keep the Struct and aliasing classes of an excluded folder that a reloaded project file requires' do
      @constants.concat(%i[ReloaderSettings ReloaderSettingsLabel])
      excluded = write('excluded/settings.rb', <<-RUBY)
        ReloaderSettings = Struct.new(:name)
        class ReloaderSettingsLabel
          alias label inspect
        end
      RUBY
      Padrino::Reloader.exclude << File.dirname(excluded)
      file = write('models/uses_settings.rb', "require #{excluded.inspect}\n")
      Padrino::Reloader.safe_load(file)
      settings = ReloaderSettings
      label = ReloaderSettingsLabel

      Padrino::Reloader.safe_load(file, force: true)
      assert_same settings, Object.const_get(:ReloaderSettings, false)
      assert_same label, Object.const_get(:ReloaderSettingsLabel, false)
    ensure
      Padrino::Reloader.exclude.delete(File.dirname(excluded)) if excluded
    end

    it 'should keep native classes that are defined outside the project, or by a C extension, and reopened in it' do
      @constants.concat(%i[ReloaderGemStruct ReloaderExtStruct])
      require 'strscan'
      Dir.mktmpdir do |gem_dir|
        File.write("#{gem_dir}/gem_struct.rb", "ReloaderGemStruct = Struct.new(:x)\n")
        require "#{gem_dir}/gem_struct.rb"
        $LOADED_FEATURES.delete("#{gem_dir}/gem_struct.rb")
      end
      # A C extension installed in the project (in vendor/bundle, say) defines its classes at line 0 of the library.
      TOPLEVEL_BINDING.eval('ReloaderExtStruct = Struct.new(:x)', "#{@dir}/vendor/ext.so", 0)
      load write('models/reopen.rb', <<-RUBY)
        class ReloaderGemStruct
          def double
            x * 2
          end
        end
        class StringScanner
          def reloader_reopened; end
        end
      RUBY

      [ReloaderGemStruct, ReloaderExtStruct, StringScanner].each do |klass|
        Padrino::Reloader.remove_constant(klass)
        assert_same klass, Object.const_get(klass.name, false), "#{klass} was removed"
      end
    ensure
      StringScanner.send(:remove_method, :reloader_reopened) if StringScanner.method_defined?(:reloader_reopened, false)
    end

    it 'should reset a project concern with methods not written in Ruby, and only that one' do
      @constants.concat(%i[ReloaderNativeConcern ReloaderGemConcern])
      source = "module %s\n  define_method(:label, Kernel.instance_method(:inspect))\nend\n"
      load write('models/concern.rb', format(source, 'ReloaderNativeConcern'))
      Dir.mktmpdir do |gem_dir|
        File.write("#{gem_dir}/concern.rb", format(source, 'ReloaderGemConcern'))
        load "#{gem_dir}/concern.rb"
      end

      [ReloaderNativeConcern, ReloaderGemConcern].each do |concern|
        concern.instance_variable_set(:@_included_block, proc {})
        Padrino::Reloader.reset_concern(concern)
      end
      refute ReloaderNativeConcern.instance_variable_defined?(:@_included_block), 'ReloaderNativeConcern was not reset'
      assert ReloaderGemConcern.instance_variable_defined?(:@_included_block), 'ReloaderGemConcern was reset'
    end

    if RUBY_ENGINE == 'jruby'
      it 'should keep Java classes' do
        java_class = Java::JavaUtil::ArrayList
        assert Padrino::Reloader.send(:external_constant?, java_class)
        Padrino::Reloader.remove_constant(java_class)
        assert_same java_class, Java::JavaUtil::ArrayList
      end
    end
  end
end
