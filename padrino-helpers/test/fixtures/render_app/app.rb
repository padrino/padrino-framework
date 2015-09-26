PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
RACK_ENV = 'test' unless defined? RACK_ENV

require 'padrino-core'

class RenderUser
  attr_accessor :name
  def initialize(name); @name = name; end
end

class RenderDemo < Padrino::Application
  register Padrino::Helpers

  configure do
    set :logging, false
    set :padrino_logging, false
    set :environment, :test
  end

  # get current engines from partials
  get '/current_engine' do
    render :current_engine
  end

  # get current engines from explicit engine partials
  get '/explicit_engine' do
    render :explicit_engine
  end

  get '/double_capture_:ext' do
    render "double_capture_#{params[:ext]}"
  end

  get '/wrong_capture_:ext' do
    render "wrong_capture_#{params[:ext]}"
  end

  get '/ruby_block_capture_:ext' do
    render "ruby_block_capture_#{params[:ext]}"
  end

  # partial with object
  get '/partial/object' do
    partial 'template/user', :object => RenderUser.new('John'), :locals => { :extra => "bar" }
  end

  # partial with collection
  get '/partial/collection' do
    partial 'template/user', :collection => [RenderUser.new('John'), RenderUser.new('Billy')], :locals => { :extra => "bar" }
  end

  # partial with collection and ext
  get '/partial/collection.ext' do
    partial 'template/user.haml', :collection => [RenderUser.new('John'), RenderUser.new('Billy')], :locals => { :extra => "bar" }
  end

  # partial with locals
  get '/partial/locals' do
    partial 'template/user', :locals => { :user => RenderUser.new('John'), :extra => "bar" }
  end

  # partial starting with forward slash
  get '/partial/foward_slash' do
    partial '/template/user', :object => RenderUser.new('John'), :locals => { :extra => "bar" }
  end

  # partial with unsafe engine
  get '/partial/unsafe' do
    block = params[:block] ? proc{ params[:block] } : nil
    partial 'unsafe.html.builder', &block
  end

  get '/partial/unsafe_one' do
    block = params[:block] ? proc{ params[:block] } : nil
    partial 'unsafe_object', :object => 'Mary', &block
  end

  get '/partial/unsafe_many' do
    block = params[:block] ? proc{ params[:block] } : nil
    partial 'unsafe_object', :collection => ['John', 'Mary'], &block
  end

  get '/render_block_:ext' do
    render "render_block_#{params[:ext]}" do
      content_tag :div, 'go block!'
    end
  end

  get '/partial_block_:ext' do
    partial "partial_block_#{params[:ext]}" do
      content_tag :div, 'go block!'
    end
  end

  helpers do
    def dive_helper(ext)
      # @current_engine, save = nil
      form_result = form_tag '/' do
        render "dive_inner_#{ext}"
      end
      # @current_engine = save
      content_tag('div', form_result, :class => 'wrapper')
    end
  end

  get '/double_dive_:ext' do
    @ext = params[:ext]
    render "dive_outer_#{@ext}"
  end
end
