require_relative 'helper'

describe 'Padrino::Server' do
  describe 'detect_rack_handler' do
    def with_available_handlers(*available, &block)
      get = lambda do |name|
        raise LoadError, name unless available.include?(name)

        Object
      end
      Rackup::Handler.stub(:get, get, &block)
    end

    it 'should detect falcon when it is the only server available' do
      with_available_handlers('falcon') do
        assert_equal :falcon, Padrino::Server.detect_rack_handler
      end
    end

    it 'should prefer puma over falcon' do
      with_available_handlers('falcon', 'puma') do
        assert_equal :puma, Padrino::Server.detect_rack_handler
      end
    end

    it 'should raise when no server is available' do
      with_available_handlers do
        assert_raises(RuntimeError) { Padrino::Server.detect_rack_handler }
      end
    end
  end
end
