require File.expand_path('../helper', __FILE__)
require 'slim'

describe 'A template alone' do

  module Templater1
    include Padrino::Templates

    set :default_layout, :layout2

    # Inherit templates
    template(:page){ 'h1 Hello World!' }

    def self.example
      slim :hello
    end
  end

  class Templater2
    include Templater1

    def self.example
      slim :page, layout: false
    end
  end

  class Templater3 < Templater2

    def self.example
      slim :page
    end

    def example2
      slim :page
    end
  end

  it 'works alone' do
    assert_equal '<h1>Slim Layout!</h1><p><h1>Hello From Slim</h1></p>', Templater1.example
  end

  it 'can be included in another module' do
    assert_equal '<h1>Hello World!</h1>', Templater2.example
  end

  it 'can be inherited from a singleton class' do
    assert_equal '<h1>Slim Layout!</h1><p><h1>Hello World!</h1></p>', Templater3.example
  end

  it 'can be inherited from a instance of a class' do
    assert_equal Templater3.example, Templater3.new.example2
  end

  it 'works under an anonymous class' do
    assert_equal '<h1>Slim Layout!</h1><p><h1>Hello World!</h1></p>', Class.new(Templater3).example
  end
end
