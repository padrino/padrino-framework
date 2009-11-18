require 'sinatra/base'
require 'haml'

class RenderUser
  attr_accessor :name
  def initialize(name); @name = name; end
end

class RenderDemo < Sinatra::Base
  register Padrino::Helpers
  
  configure do
    set :root, File.dirname(__FILE__)
  end
  
  # haml_template
  get '/render_haml' do
    @template = 'haml'
    haml_template 'haml/test'
  end
  
  # erb_template
  get '/render_erb' do
    @template = 'erb'
    erb_template 'erb/test'
  end
  
  # render_template with explicit engine
  get '/render_template/:engine' do
    @template = params[:engine]
    render_template "template/#{@template}_template", :template_engine => @template
  end
  
  # render_template without explicit engine
  get '/render_template' do
    render_template "template/some_template"
  end
  
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