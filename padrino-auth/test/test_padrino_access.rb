require File.expand_path('../helper', __FILE__)

describe "Padrino::Access" do
  before do
    @bender = OpenStruct.new :name => 'Bender Bending Rodriguez', :role => :robots
    @leela = OpenStruct.new :name => 'Turanga Leela', :role => :mutants
    @fry = OpenStruct.new :name => 'Philip J. Fry', :role => :humans
    @ami = OpenStruct.new :name => 'Amy Wong', :role => :humans
    @zoidberg = OpenStruct.new :name => 'Dr. John A. Zoidberg', :role => :lobsters
    mock_app do
      set :access_subject, :credentials
      register Padrino::Access
      set :credentials, nil
      helpers do
        def credentials
          settings.credentials
        end
      end
      get(:index){ 'foo' }
      get(:bend){ 'bend' }
      get(:stop_partying){ 'stop partying' }
      controller :surface do
        get(:live) { 'live on the surface' }
      end
      controller :sewers do
        get(:live) { 'live in the sewers' }
        get(:visit) { 'visit the sewers' }
      end
    end
  end

  should 'register with authorization module' do
    assert @app.respond_to? :set_access
    assert_kind_of Padrino::Permissions, @app.permissions
  end

  should 'set wildcard access' do
    deny
    set_access :*
    allow
  end

  should 'reset access properly' do
    set_access :robots
    allow @bender
    @app.reset_access!
    deny @bender
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
end
