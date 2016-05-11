require File.expand_path(File.dirname(__FILE__) + '/helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/kiq')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/system')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/static')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/custom_dependencies/custom_dependencies')

describe "SystemReloader" do
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
      Padrino.mount(SystemDemo).to("/")
      assert_equal Child.new.family, 'Danes'
      parent_file = File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/models/parent.rb')
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
        File.open(parent_file, "w") { |f| f.write(new_class) }
        Padrino::Reloader.reload!
        assert_equal 'Dancy', Parent.new.family
        assert_equal 'Shmancy', Parent.new.shmamily
        assert_equal 'Dancy', Child.new.family
        assert_equal 'Shmancy', Child.new.shmamily
      ensure
        File.open(parent_file, "w") { |f| f.write(backup) }
      end
    end

    it 'should not fail horribly on reload event with non-padrino apps' do
      Padrino.mount("kiq").to("/")
      Padrino.reload!
    end

    it 'should not reload apps with disabled reload' do
      Padrino.mount(StaticDemo).to("/")
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
      tmp_file = '/tmp/padrino_class_demo.rb'
      begin
        File.open(tmp_file, "w") { |f| f.write(new_class) }
        Padrino.clear!
        require File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/system_class_methods_demo.rb')
        @app = SystemClassMethodsDemo
        Padrino.mount(SystemClassMethodsDemo).to("/")
        get '/'
        assert defined?(SingletonClassTest), 'SingletonClassTest undefined'
        assert_includes SingletonClassTest.singleton_methods, :external_test
        FileUtils.touch File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/helpers/class_methods_helpers.rb')
        Padrino.reload!
        assert defined?(SingletonClassTest), 'SingletonClassTest undefined'
        assert_includes SingletonClassTest.singleton_methods, :external_test
      ensure
        FileUtils.rm tmp_file
      end
    end

    it 'should not touch external constants defining instance methods' do
      new_class = <<-DOC
        class InstanceTest
          def instance_test
          end
        end
      DOC
      tmp_file = '/tmp/padrino_instance_demo.rb'
      begin
        File.open(tmp_file, "w") { |f| f.write(new_class) }
        Padrino.clear!
        require File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/system_instance_methods_demo.rb')
        @app = SystemInstanceMethodsDemo
        Padrino.mount(SystemInstanceMethodsDemo).to("/")
        get '/'
        assert defined?(InstanceTest), 'InstanceTest undefined'
        assert_includes InstanceTest.new.methods, :instance_test
        FileUtils.touch File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/helpers/instance_methods_helpers.rb')
        Padrino.reload!
        assert defined?(InstanceTest), 'InstanceTest undefined'
        assert_includes InstanceTest.new.methods, :instance_test
      ensure
        FileUtils.rm tmp_file
      end
    end

    it 'should not fail with superclass mismatch when reloading descendant classes with no instances' do
      Padrino.clear!
      require File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/stealthy/app.rb')
      @app = SystemStealthyClassDemo
      Padrino.mount(SystemStealthyClassDemo).to("/")
      get '/'
      FileUtils.touch File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/stealthy/helpers/stealthy_class_helpers.rb')
      Padrino.reload!
    end
  end

  describe 'reloading custom dependencies' do
    let(:custom_dependency_path) { File.dirname(__FILE__) + '/fixtures/apps/custom_dependencies/my_dependencies' }
    let(:custom_dependency) { File.join(custom_dependency_path, 'my_dependency.rb') }

    before do
      @app = CustomDependencies
      Padrino.clear!
      Padrino.mount(CustomDependencies).to("/")
      Padrino.dependency_paths << custom_dependency_path + '/*.rb'
      Padrino.load!
      get '/'
    end

    it 'should discover changed dependencies' do
      FileUtils.touch(custom_dependency)
      assert Padrino::Reloader.changed?, 'Change to custom dependency has not been recognised'
    end
  end

  describe 'reloading module constants' do
    it 'should remove constants of misdesigned modules' do
      skip
      Padrino.clear!
      require File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/concerned/app.rb')
      @app = SystemConcernedClassDemo
      Padrino.mount(SystemConcernedClassDemo).to("/")
      get '/'

      original_value = BadModule.instance_variable_get(:@happy_global_variable)
      FileUtils.touch File.dirname(__FILE__) + '/fixtures/apps/concerned/models/mixins/badmodule.rb'
      Padrino.reload!
      assert_equal original_value, BadModule.instance_variable_get(:@happy_global_variable)
    end
  end
end
