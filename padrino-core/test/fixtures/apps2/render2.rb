PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

class RenderDemo2 < Padrino::Application
  set :reload, true
end

RenderDemo2.controllers :blog2 do
  get '/override' do
    render 'post', :layout => RenderDemo.layout_path('specific') 
  end
end

Padrino.load!
