require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Padrino::Reloader::Storage" do
  describe "#classes" do
    it 'should take an snapshot of the current loaded classes' do
      snapshot = Padrino::Reloader::Storage.send(:object_classes)
      assert_equal snapshot.include?(Padrino::Logger), true
    end

    it 'should return a Set object' do
      snapshot = Padrino::Reloader::Storage.send(:object_classes)
      assert_equal snapshot.kind_of?(Set), true
    end

    it 'should be able to process a the class name given a block' do
      klasses = Padrino::Reloader::Storage.send(:object_classes) do |klass|
        next unless klass.respond_to?(:name) # fix JRuby < 1.7.22
        if klass.name =~ /^Padrino::/
          klass
        end
      end

      assert_equal (klasses.size > 1), true
      klasses.each do |klass|
        assert_match(/^Padrino::/, klass.to_s)
      end
    end
  end

  describe "#new_classes" do
    before do
      @snapshot = Padrino::Reloader::Storage.send(:object_classes)
    end

    it 'should return list of new classes' do
      skip
      class OSTest; end
      module OSTestModule; class B; end; end

      new_classes = Padrino::Reloader::Storage.send(:new_classes, @snapshot)

      assert_equal new_classes.size, 3
      assert_equal new_classes.include?(OSTest), true
      assert_equal new_classes.include?(OSTestModule::B), true
    end

    it 'should return a Set object' do
      new_classes = Padrino::Reloader::Storage.send(:new_classes, @snapshot)
      assert_equal new_classes.kind_of?(Set), true
    end
  end
end
