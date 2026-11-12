require_relative 'helper'
require 'tmpdir'

require_relative 'fixtures/apps/kiq'
require_relative 'fixtures/apps/system'
require_relative 'fixtures/apps/static'
require_relative 'fixtures/apps/custom_dependencies/custom_dependencies'

describe 'SystemReloader' do
  describe 'for wierd and difficult reload events' do
    before do
      @app = SystemDemo
      get '/'
    end

    it 'should reload system features if they were required only in helper' do
      @app.reload!
      get '/'
      assert_equal 'Resolv', body
    end

    it 'should reload children on parent change' do
      Padrino.mount(SystemDemo).to('/')
      assert_equal Child.new.family, 'Danes'
      parent_file = File.expand_path("#{__dir__}/fixtures/apps/models/parent.rb")
      new_class = <<-DOC
        class Parent
          def family
            'Dancy'
          end
          def shmamily
            'Shmancy'
          end
        end
      DOC
      begin
        backup = File.read(parent_file)
        Padrino::Reloader.reload!
        assert_equal 'Danes', Parent.new.family
        assert_equal 'Danes', Child.new.family
        File.open(parent_file, 'w') { |f| f.write(new_class) }
        Padrino::Reloader.reload!
        assert_equal 'Dancy', Parent.new.family
        assert_equal 'Shmancy', Parent.new.shmamily
        assert_equal 'Dancy', Child.new.family
        assert_equal 'Shmancy', Child.new.shmamily
      ensure
        File.open(parent_file, 'w') { |f| f.write(backup) }
      end
    end

    it 'should not fail horribly on reload event with non-padrino apps' do
      Padrino.mount('kiq').to('/')
      Padrino.reload!
    end

    it 'should not reload apps with disabled reload' do
      Padrino.mount(StaticDemo).to('/')
      Padrino.reload!
    end
  end

  describe 'reloading external constants' do
    it 'should not touch external constants defining singleton methods' do
      new_class = <<-DOC
        class SingletonClassTest
          def self.external_test
          end
        end
      DOC
      gem_dir = Dir.mktmpdir
      File.write(File.join(gem_dir, 'padrino_class_demo.rb'), new_class)
      $LOAD_PATH.unshift(gem_dir)
      begin
        Padrino.clear!
        require File.expand_path("#{__dir__}/fixtures/apps/system_class_methods_demo.rb")
        @app = SystemClassMethodsDemo
        Padrino.mount(SystemClassMethodsDemo).to('/')
        get '/'
        assert defined?(SingletonClassTest), 'SingletonClassTest undefined'
        assert_includes SingletonClassTest.singleton_methods, :external_test
        FileUtils.touch File.expand_path("#{__dir__}/fixtures/apps/helpers/class_methods_helpers.rb")
        Padrino.reload!
        assert defined?(SingletonClassTest), 'SingletonClassTest undefined'
        assert_includes SingletonClassTest.singleton_methods, :external_test
      ensure
        $LOAD_PATH.delete(gem_dir)
        FileUtils.rm_rf(gem_dir)
      end
    end

    it 'should not touch external constants defining instance methods' do
      new_class = <<-DOC
        class InstanceTest
          def instance_test
          end
        end
      DOC
      gem_dir = Dir.mktmpdir
      File.write(File.join(gem_dir, 'padrino_instance_demo.rb'), new_class)
      $LOAD_PATH.unshift(gem_dir)
      begin
        Padrino.clear!
        require File.expand_path("#{__dir__}/fixtures/apps/system_instance_methods_demo.rb")
        @app = SystemInstanceMethodsDemo
        Padrino.mount(SystemInstanceMethodsDemo).to('/')
        get '/'
        assert defined?(InstanceTest), 'InstanceTest undefined'
        assert_includes InstanceTest.new.methods, :instance_test
        FileUtils.touch File.expand_path("#{__dir__}/fixtures/apps/helpers/instance_methods_helpers.rb")
        Padrino.reload!
        assert defined?(InstanceTest), 'InstanceTest undefined'
        assert_includes InstanceTest.new.methods, :instance_test
      ensure
        $LOAD_PATH.delete(gem_dir)
        FileUtils.rm_rf(gem_dir)
      end
    end

    it 'should not fail with superclass mismatch when reloading descendant classes with no instances' do
      Padrino.clear!
      require File.expand_path("#{__dir__}/fixtures/apps/stealthy/app.rb")
      @app = SystemStealthyClassDemo
      Padrino.mount(SystemStealthyClassDemo).to('/')
      get '/'
      FileUtils.touch File.expand_path("#{__dir__}/fixtures/apps/stealthy/helpers/stealthy_class_helpers.rb")
      Padrino.reload!
    end

    it 'should keep method-less external constants first required from an app file' do
      gem_dir = Dir.mktmpdir
      File.write(File.join(gem_dir, 'padrino_reloader_fake_gem.rb'), <<-DOC)
        module PadrinoReloaderFakeGem
          class Error < StandardError
          end
        end
      DOC
      $LOAD_PATH.unshift(gem_dir)
      begin
        Padrino.clear!
        require File.expand_path("#{__dir__}/fixtures/apps/external_constants/app.rb")
        @app = SystemExternalConstantsDemo
        Padrino.mount(SystemExternalConstantsDemo).to('/')
        get '/'
        assert defined?(PadrinoReloaderFakeGem::Error), 'PadrinoReloaderFakeGem::Error was removed by the first reload'
        app_error = ExternalConstantsAppError
        FileUtils.touch File.expand_path("#{__dir__}/fixtures/apps/external_constants/helpers/external_constants_helpers.rb")
        Padrino.reload!
        assert defined?(PadrinoReloaderFakeGem::Error), 'PadrinoReloaderFakeGem::Error was removed on reload'
        assert defined?(ExternalConstantsAppError), 'ExternalConstantsAppError undefined'
        refute_same app_error, ExternalConstantsAppError, 'ExternalConstantsAppError was not reloaded'
      ensure
        $LOAD_PATH.delete(gem_dir)
        FileUtils.rm_rf(gem_dir)
      end
    end

    it 'should keep constants from an excluded folder that an app file requires' do
      support_dir = File.expand_path("#{__dir__}/fixtures/apps/excluded_constants/support")
      Padrino::Reloader.exclude << support_dir
      Padrino.clear!
      require File.expand_path("#{__dir__}/fixtures/apps/excluded_constants/app.rb")
      @app = SystemExcludedConstantsDemo
      Padrino.mount(SystemExcludedConstantsDemo).to('/')
      get '/'
      # The excluded file isn't required again, so a removed constant would stay undefined.
      excluded_constants = -> { %w[ExcludedConstantsSettings ExcludedConstantsError].map { |name| Object.const_get(name) if Object.const_defined?(name) } }
      kept = excluded_constants.call
      assert_equal [Class, Class], kept.map(&:class), 'removed by the first reload'
      app_settings = ExcludedConstantsAppSettings
      FileUtils.touch File.expand_path("#{__dir__}/fixtures/apps/excluded_constants/helpers/excluded_constants_helpers.rb")
      Padrino.reload!
      assert_equal kept, excluded_constants.call, 'removed on reload'
      assert defined?(ExcludedConstantsAppSettings), 'ExcludedConstantsAppSettings undefined'
      refute_same app_settings, ExcludedConstantsAppSettings, 'ExcludedConstantsAppSettings was not reloaded'
    ensure
      Padrino::Reloader.exclude.delete(support_dir)
    end

    it 'should redefine classes from an excluded folder that an app file loads' do
      support_dir = File.expand_path("#{__dir__}/fixtures/apps/loaded_excluded/support")
      Padrino::Reloader.exclude << support_dir
      Padrino.clear!
      require File.expand_path("#{__dir__}/fixtures/apps/loaded_excluded/app.rb")
      @app = SystemLoadedExcludedDemo
      Padrino.mount(SystemLoadedExcludedDemo).to('/')
      get '/'
      thing = LoadedExcludedThing
      point = LoadedExcludedPoint
      # The app file runs the excluded file again with load, so a kept class would raise superclass mismatch.
      FileUtils.touch File.expand_path("#{__dir__}/fixtures/apps/loaded_excluded/helpers/loaded_excluded_helpers.rb")
      Padrino.reload!
      refute_same thing, LoadedExcludedThing, 'LoadedExcludedThing was not reloaded'
      assert_same LoadedExcludedBase, LoadedExcludedThing.superclass
      refute_same point, LoadedExcludedPoint, 'LoadedExcludedPoint was not reloaded'
      assert_equal 3, LoadedExcludedPoint.new(1, 2).sum
    ensure
      Padrino::Reloader.exclude.delete(support_dir)
    end
  end

  describe 'reloading custom dependencies' do
    let(:custom_dependency_path) { "#{__dir__}/fixtures/apps/custom_dependencies/my_dependencies" }
    let(:custom_dependency) { File.join(custom_dependency_path, 'my_dependency.rb') }

    before do
      @app = CustomDependencies
      Padrino.clear!
      Padrino.mount(CustomDependencies).to('/')
      Padrino.dependency_paths << "#{custom_dependency_path}/*.rb"
      Padrino.load!
      get '/'
    end

    it 'should discover changed dependencies' do
      FileUtils.touch(custom_dependency)
      assert Padrino::Reloader.changed?, 'Change to custom dependency has not been recognised'
    end

    it 'should discover changed dependencies in a folder whose name starts with an excluded one' do
      excluded = File.join(File.dirname(custom_dependency_path), 'my')
      Padrino::Reloader.exclude << excluded
      FileUtils.touch(custom_dependency)
      assert Padrino::Reloader.changed?, 'Change to custom dependency has not been recognised'
    ensure
      Padrino::Reloader.exclude.delete(excluded)
    end
  end

  describe 'reloading module constants' do
    it 'should remove constants of misdesigned modules' do
      skip
      Padrino.clear!
      require File.expand_path("#{__dir__}/fixtures/apps/concerned/app.rb")
      @app = SystemConcernedClassDemo
      Padrino.mount(SystemConcernedClassDemo).to('/')
      get '/'

      original_value = BadModule.instance_variable_get(:@happy_global_variable)
      FileUtils.touch "#{__dir__}/fixtures/apps/concerned/models/mixins/badmodule.rb"
      Padrino.reload!
      assert_equal original_value, BadModule.instance_variable_get(:@happy_global_variable)
    end

    it 'should redefine an ActiveSupport::Concern whose included block moved' do
      begin
        require 'active_support/concern'
      rescue LoadError
        skip 'ActiveSupport is not available'
      end
      concern_file = "#{__dir__}/fixtures/apps/concerned/models/mixins/filterable.rb"
      includer_file = "#{__dir__}/fixtures/apps/concerned/models/filtered_item.rb"
      original = File.read(concern_file)
      includer_mtime = File.mtime(includer_file)
      Padrino.clear!
      require File.expand_path("#{__dir__}/fixtures/apps/concerned/app.rb")
      @app = SystemConcernedClassDemo
      Padrino.mount(SystemConcernedClassDemo).to('/')
      get '/'
      assert_equal 'v1', FilteredItem.new.filter
      Filterable.instance_variable_set(:@config, :kept)

      # A second edit checks that the concern stays tracked after its first reload.
      [2, 3].each do |version|
        File.write(concern_file, original.sub('  included do', "#{"  # moved\n" * version}  included do")
                                         .sub("'v1'", "'v#{version}'").sub("'l1'", "'l#{version}'"))
        FileUtils.touch(concern_file, mtime: Time.now + version)
        Padrino.reload!
        assert_equal "l#{version}", FilteredItem.new.label
        FileUtils.touch(includer_file, mtime: Time.now + version)
        Padrino.reload!
        assert_equal "v#{version}", FilteredItem.new.filter
      end
      assert_equal :kept, Filterable.instance_variable_get(:@config)
    ensure
      File.write(concern_file, original) if original
      # A future mtime would hide the next run's touch from Reloader.
      File.utime(includer_mtime, includer_mtime, includer_file) if includer_mtime
    end

    it 'should redefine an ActiveSupport::Concern that another file requires, also after Padrino.clear!' do
      begin
        require 'active_support/concern'
      rescue LoadError
        skip 'ActiveSupport is not available'
      end
      concern_file = "#{__dir__}/fixtures/apps/concerned/models/mixins/sortable.rb"
      includer_file = "#{__dir__}/fixtures/apps/concerned/models/catalog_item.rb"
      original = File.read(concern_file)
      includer_mtime = File.mtime(includer_file)
      # Sortable stays defined after Padrino.clear!, so the second load finds it already defined.
      2.times do
        Padrino.clear!
        require File.expand_path("#{__dir__}/fixtures/apps/concerned/app.rb")
        @app = SystemConcernedClassDemo
        Padrino.mount(SystemConcernedClassDemo).to('/')
        get '/'
      end
      assert_equal 's1', CatalogItem.new.sort_key

      [2, 3].each do |version|
        File.write(concern_file, original.sub('  included do', "#{"  # moved\n" * version}  included do").gsub("'s1'", "'s#{version}'"))
        FileUtils.touch(concern_file, mtime: Time.now + version)
        Padrino.reload!
        assert_equal "s#{version}", CatalogItem.new.sort_label
        FileUtils.touch(includer_file, mtime: Time.now + version)
        Padrino.reload!
        assert_equal "s#{version}", CatalogItem.new.sort_key
      end
    ensure
      if original
        File.write(concern_file, original)
        File.utime(includer_mtime, includer_mtime, includer_file)
        # The next Padrino.clear! keeps Sortable, and CatalogItem then requires the restored file without a reset.
        Padrino::Reloader.reset_concern(Sortable) if defined?(Sortable)
      end
    end

    it 'should redefine an ActiveSupport::Concern that overrides name' do
      begin
        require 'active_support/concern'
      rescue LoadError
        skip 'ActiveSupport is not available'
      end
      concern_file = "#{__dir__}/fixtures/apps/concerned/models/mixins/branded.rb"
      includer_file = "#{__dir__}/fixtures/apps/concerned/models/branded_item.rb"
      original = File.read(concern_file)
      concern_mtime = File.mtime(concern_file)
      includer_mtime = File.mtime(includer_file)
      Padrino.clear!
      require File.expand_path("#{__dir__}/fixtures/apps/concerned/app.rb")
      @app = SystemConcernedClassDemo
      Padrino.mount(SystemConcernedClassDemo).to('/')
      get '/'
      assert_equal 'b1', BrandedItem.new.brand

      File.write(concern_file, original.sub('  included do', "  # moved\n  included do").sub("'b1'", "'b2'"))
      FileUtils.touch(concern_file, mtime: Time.now + 2)
      Padrino.reload!
      FileUtils.touch(includer_file, mtime: Time.now + 2)
      Padrino.reload!
      assert_equal 'b2', BrandedItem.new.brand
    ensure
      if original
        File.write(concern_file, original)
        File.utime(concern_mtime, concern_mtime, concern_file)
      end
      File.utime(includer_mtime, includer_mtime, includer_file) if includer_mtime
    end

    it 'should not call methods on deprecated constant proxies while looking for concerns' do
      begin
        require 'active_support'
        require 'active_support/deprecation'
      rescue LoadError
        skip 'ActiveSupport is not available'
      end
      # A proxy is a Module that warns, or raises with this behavior, on any method call,
      # so the test only keeps a reference to it and never calls it.
      deprecator = ActiveSupport::Deprecation.new
      deprecator.behavior = :raise
      _proxy = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ReloaderDeprecatedMonitor', '::Monitor', deprecator)
      Padrino.clear!
      require File.expand_path("#{__dir__}/fixtures/apps/concerned/app.rb")
      @app = SystemConcernedClassDemo
      Padrino.mount(SystemConcernedClassDemo).to('/')
      get '/'
      assert_equal 'l1', FilteredItem.new.label
    end
  end
end
