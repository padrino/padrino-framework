require File.expand_path('../helper', __FILE__)
require 'slim'

describe 'A template alone' do

  module Mod1
    include Padrino::Templates
  end

  class Cls1
    include Padrino::Templates
    set :foo, :bar
  end

  class Cls2 < Cls1
  end

  it 'has a default layout' do
    assert_equal :layout, Mod1.default_layout
    assert_equal :layout, Cls1.default_layout
    assert_equal :layout, Cls2.default_layout
  end

  it 'change correctly values' do
  end

  it 'render a basic template' do
    assert_equal '<h1>Hello</h1>', Mod1.slim('h1 Hello', layout: false)
  end
end
