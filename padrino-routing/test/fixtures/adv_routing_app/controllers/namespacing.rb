AdvRoutingDemo.controllers :admin do
  get :dashboard do
    "<h1>This is the admin dashboard, id: #{params[:id]}</h1>"
  end

  get :panel, :map => "/admin/panel/:name/thing" do
    "<h1>This is the admin panel, name: #{params[:name]}</h1>"
  end
  
  get :simple, :map => '/admin/simple' do
    "<h1>This is the admin simple</h1>"
  end
  
  get :settings do
    "<h1>This is the settings</h1>"
  end
end


AdvRoutingDemo.controllers do
  namespace :blog do
    get :index, :map => "/blog/index/action" do
      "<h1>Here is the blog</h1>"
    end
  end
end