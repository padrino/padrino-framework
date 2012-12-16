require File.expand_path('../helper', __FILE__)

describe 'Extensions' do
  module FooExtensions
    def foo
    end

    private
    def im_hiding_in_ur_foos
    end
  end

  module BarExtensions
    def bar
    end
  end

  module BazExtensions
    def baz
    end
  end

  module QuuxExtensions
    def quux
    end
  end

  module PainExtensions
    def foo=(name); end
    def bar?(name); end
    def fizz!(name); end
  end

  it 'will add the methods to the DSL for the class in which you register them and its subclasses' do
    Padrino::Application.register FooExtensions
    assert Padrino::Application.respond_to?(:foo)
  end

  it 'allows extending by passing a block' do
    Padrino::Application.register {
      def im_in_ur_anonymous_module; end
    }
    assert Padrino::Application.respond_to?(:im_in_ur_anonymous_module)
  end

  module BizzleExtension
    module ClassMethods
      def bizzle
        bizzle_option
      end
    end

    def self.registered(base)
      base.extend(ClassMethods)
      fail "base should be BizzleApp" unless base == BizzleApp
      fail "base should have already extended BizzleExtension" unless base.respond_to?(:bizzle)
      base.set :bizzle_option, 'bizzle!'
    end
  end

  class BizzleApp < Padrino::Application
  end

  it 'sends .registered to the extension module after extending the class' do
    BizzleApp.register BizzleExtension
    assert_equal 'bizzle!', BizzleApp.bizzle_option
    assert_equal 'bizzle!', BizzleApp.bizzle
  end
end
