require File.expand_path('../helper', __FILE__)

describe "Padrino::Access" do
  before do
    mock_app do
      set :credentials_reader, :visitor
      register Padrino::Access
      set_access :*, :allow => :login
      set :users, Character.all
      get(:login, :with => :id) do
        user = settings.users.find{ |user| user.id.to_s == params[:id] }
        self.send(:"#{settings.credentials_reader}=", user)
      end
      get(:index){ 'foo' }
      get(:bend){ 'bend' }
      get(:subject){ self.send(settings.credentials_reader).inspect }
      get(:stop_partying){ 'stop partying' }
      controller :surface do
        get(:live) { 'live on the surface' }
      end
      controller :sewers do
        get(:live) { 'live in the sewers' }
        get(:visit) { 'visit the sewers' }
      end
      set :fake_session, {}
      helpers do
        def visitor
          settings.fake_session[:visitor]
        end
        def visitor=(user)
          settings.fake_session[:visitor] = user
        end
      end
    end
    Character.all.each do |user|
      instance_variable_set :"@#{user.id}", user
    end
  end

  should 'register with authorization module' do
    assert @app.respond_to? :set_access
    assert_kind_of Padrino::Permissions, @app.permissions
  end

  should 'properly detect access subject' do
    set_access :*
    get '/login/ami'
    get '/subject'
    assert_equal @ami.inspect, body
  end

  should 'reset access properly' do
    set_access :*
    allow
    @app.reset_access!
    deny
  end

  should 'set group access' do
    # only humans should be allowed on TV
    set_access :humans
    allow @fry
    deny @bender
  end

  should 'set individual access' do
    # only Fry should be allowed to romance Leela
    set_access @fry
    allow @fry
    deny @ami
  end

  should 'set mixed individual and group access' do
    # only humans and Leela should be allowed on the surface
    set_access :humans
    set_access @leela
    allow @fry
    allow @leela
  end

  should 'set action-specific access' do
    # bender should be allowed to bend, and he's denied to stop partying
    set_access @bender, :allow => :bend
    set_access @fry, :allow => :stop_partying
    allow @bender, '/bend'
    deny @bender, '/stop_partying'
    allow @fry, '/stop_partying'
    deny @fry, '/bend'
  end

  should 'set object-specific access' do
    # only humans and Leela should be allowed to live on the surface
    # only mutants should be allowed to live in the sewers though humans can visit
    set_access :humans, :allow => :live, :with => :surface
    set_access :mutants, :allow => :live, :with => :sewers
    set_access @leela, :allow => :live, :with => :surface
    set_access :humans, :allow => :visit, :with => :sewers
    allow @fry, '/surface/live'
    deny @fry, '/sewers/live'
    allow @fry, '/sewers/visit'
    allow @leela, '/surface/live'
    allow @leela, '/sewers/live'
  end

  should 'detect object when setting access from controller' do
    # only humans and lobsters should have binocular vision
    @app.controller :binocular do
      set_access :humans, :lobsters
      get(:vision) { 'binocular vision' }
    end
    deny @fry, '/'
    allow @fry, '/binocular/vision'
    allow @zoidberg, '/binocular/vision'
    deny @leela, '/binocular/vision'
  end
end
