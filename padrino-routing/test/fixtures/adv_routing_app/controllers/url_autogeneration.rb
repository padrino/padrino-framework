AdvRoutingDemo::controllers do
  get :simple, :map => "/some/simple/action" do
    "<h1>simple action welcomes you</h1>"
  end
  
  get :hello, :map => "/some/hello/action/:id/param" do
    "<h1>hello params id is #{params[:id]}</h1>"
  end
  
  get :multiple, :map => '/some/:name/and/:id' do
    "<h1>id is #{params[:id]}, name is #{params[:name]}</h1>"
  end
  
  get :test do
    "<h1>This is a test action, id: #{params[:id]}</h1>"
  end
end