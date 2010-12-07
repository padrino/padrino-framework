PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
PADRINO_ENV = 'test' unless defined? PADRINO_ENV

require 'padrino-core'

class RenderUser
  attr_accessor :name
  def initialize(name); @name = name; end
end

class RenderDemo < Padrino::Application
  register Padrino::Helpers

  # partial with object
  get '/partial/object' do
    partial 'template/user', :object => RenderUser.new('John'), :locals => { :extra => "bar" }
  end

  # partial with collection
  get '/partial/collection' do
    partial 'template/user', :collection => [RenderUser.new('John'), RenderUser.new('Billy')], :locals => { :extra => "bar" }
  end

  # partial with locals
  get '/partial/locals' do
    partial 'template/user', :locals => { :user => RenderUser.new('John'), :extra => "bar" }
  end
end