PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

class RenderDemo < Padrino::Application
  set :reload, true
end

RenderDemo.controllers :blog do
  get '/' do
    render 'post'
  end

  get '/override' do
  	render 'post', :layout => RenderDemo.layout_path('specific') 
  end
end

Padrino.load!
