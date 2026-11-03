require_relative 'helper'

describe 'Padrino::Reloader::Storage' do
  describe '#classes' do
    it 'should take an snapshot of the current loaded classes' do
      snapshot = Padrino::Reloader::Storage.send(:object_classes)
      assert_equal snapshot.include?(Padrino::Logger), true
    end

    it 'should return a Set object' do
      snapshot = Padrino::Reloader::Storage.send(:object_classes)
      assert_equal snapshot.is_a?(Set), true
    end

    it 'should be able to process a the class name given a block' do
      klasses = Padrino::Reloader::Storage.send(:object_classes) do |klass|
        next unless klass.respond_to?(:name) # fix JRuby < 1.7.22

        klass if klass.name =~ /^Padrino::/
      end

      assert_equal (klasses.size > 1), true
      klasses.each { |klass| assert_match(/^Padrino::/, klass.to_s) }
    end

    it 'should include classes that a parent hides from its subclasses method' do
      parent = Class.new do
        def self.subclasses
          []
        end
      end
      child = Class.new(parent)

      assert_includes Padrino::Reloader::Storage.send(:object_classes), child
    end
  end

  describe '#new_classes' do
    before do
      @snapshot = Padrino::Reloader::Storage.send(:object_classes)
    end

    it 'should return list of new classes' do
      class OSTest; end
      module OSTestModule; class B; end; end

      new_classes = Padrino::Reloader::Storage.send(:new_classes, @snapshot)

      assert_includes new_classes, OSTest
      assert_includes new_classes, OSTestModule::B
      refute_includes new_classes, Padrino::Logger
    end

    it 'should return a Set object' do
      new_classes = Padrino::Reloader::Storage.send(:new_classes, @snapshot)
      assert_equal new_classes.is_a?(Set), true
    end
  end

  describe 'tracking a file' do
    before do
      @storage = Padrino::Reloader::Storage
    end

    after do
      @storage.remove('storage_tracked_file.rb')
      Object.send(:remove_const, :StorageTrackedClass) if Object.const_defined?(:StorageTrackedClass, false)
    end

    def track_file
      @storage.prepare('storage_tracked_file.rb')
      Object.const_set(:StorageTrackedClass, Class.new)
      @storage.commit('storage_tracked_file.rb')
      @storage.send(:files)['storage_tracked_file.rb'][:constants]
    end

    it 'should find the classes a file defines without scanning the heap' do
      skip 'this Ruby scans the heap' unless @storage.const_get(:SUBCLASSES)
      scanned = []
      each_object = ObjectSpace.method(:each_object)
      ObjectSpace.stub(:each_object, lambda { |*args, &block|
        scanned.concat(args)
        each_object.call(*args, &block)
      }) do
        assert_includes track_file, StorageTrackedClass
      end
      refute_includes scanned, Class
    end

    it 'should find the classes a file defines by scanning the heap' do
      @storage.stub(:all_classes, -> { @storage.send(:heap_classes) }) do
        assert_includes track_file, StorageTrackedClass
      end
    end
  end
end
