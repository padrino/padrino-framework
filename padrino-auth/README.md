An example of authorization-only usage:

```ruby
# sketchup some database model
module Character
  extend self

  # db model must have authenticate method which should response with credentials object on
  # the calls of { :email => 'a@b', :password => 'abc' } to authenticate by email and password
  # or { :id => 42 } to restore credentials from id saved in session or another persistance storage
  def authenticate(credentials)
    case
    when credentials[:email] && credentials[:password]
      target = all.find{ |resource| resource.id.to_s == credentials[:email] }
      target.name.gsub(/[^A-Z]/,'') == credentials[:password] ? target : nil
    when credentials.has_key?(:id)
      all.find{ |resource| resource.id == credentials[:id] }
    else
      false
    end
  end

  # example collection of users
  def all
    @all = [
      OpenStruct.new(:id => :bender,   :name => 'Bender Bending Rodriguez', :role => :robots  ),
      OpenStruct.new(:id => :leela,    :name => 'Turanga Leela',            :role => :mutants ),
      OpenStruct.new(:id => :fry,      :name => 'Philip J. Fry',            :role => :humans  ),
      OpenStruct.new(:id => :ami,      :name => 'Amy Wong',                 :role => :humans  ),
      OpenStruct.new(:id => :zoidberg, :name => 'Dr. John A. Zoidberg',     :role => :lobsters),
    ]
  end
end

module Example; end
# define an application class
class Example::App < Padrino::Application
  register Padrino::Access

  # authorization module has no built-in persistance storage, so we have to implement it:
  enable :sessions
  helpers do
    def credentials
    puts settings.permissions.inspect
      @visitor ||= Character.authenticate(:id => session[:visitor_id])
    end
    def credentials=(user)
      @visitor = user
      session[:visitor_id] = @visitor ? @visitor.id : nil
    end
  end

  # simple authentication controller
  get(:login, :with => :id) do
    # this is an example, do not authenticate by user id in real apps
    self.credentials = Character.authenticate(:id => params[:id].to_sym)
  end

  # allow everyone to visit '/login'
  set_access :*, :allow => :login

  # example action
  get(:index){ 'foo' }

  # robots are allowed to bend
  set_access :robots, :allow => :bend
  get(:bend){ 'bend' }

  # humans and robots are allowed to live on surface
  controller :surface do
    set_access :humans, :robots
    get(:live) { 'live on the surface' }
  end

  # mutants are allowed to live on surface, humans are allowed to visit
  controller :sewers do
    set_access :mutants
    set_access :humans, :allow => :visit
    get(:live) { 'live in the sewers' }
    get(:visit) { 'visit the sewers' }
  end
end
```

That's it, rackup it and see what's up:

http://localhost:9292/ => 403 shows Forbidden  
http://localhost:9292/login/leela => 200 logs Leela in

Now we can see that Leela is allowed to live in sewers:

http://localhost:9292/sewers/live => 200 live in sewers

Now check if robots can bend and humans to visit sewers:

http://localhost:9292/login/fry  
http://localhost:9292/sewers/live  
http://localhost:9292/sewers/visit

http://localhost:9292/login/bender  
http://localhost:9292/bend  
http://localhost:9292/stop_partying

TODO: add examples of using Login module and both Access and Login.
