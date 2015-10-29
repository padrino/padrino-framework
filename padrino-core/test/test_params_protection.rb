require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Padrino::ParamsProtection" do
  before do
    @teri = { 'name' => 'Teri Bauer', 'position' => 'baby' }
    @kim = { 'name' => 'Kim Bauer', 'position' => 'daughter', 'child' => @teri }
    @jack = { 'name' => 'Jack Bauer', 'position' => 'terrorist', 'child' => @kim }
    @family = { 'name' => 'Bauer', 'persons' => { 1 => @teri, 2 => @kim, 3 => @jack } }
    @jack_query = Padrino::Utils.build_uri_query(@jack)
  end

  it 'should drop all parameters except allowed ones' do
    result = nil
    mock_app do
      post :basic, :params => [ :name ] do
        result = params
        ''
      end
    end
    post '/basic?' + @jack_query
    assert_equal({ 'name' => @jack['name'] }, result)
  end

  it 'should preserve original params' do
    result = nil
    mock_app do
      post :basic, :params => [ :name ] do
        result = original_params
        ''
      end
    end
    post '/basic?' + @jack_query
    assert_equal(@jack, result)
  end

  it 'should work with recursive data' do
    result = nil
    mock_app do
      post :basic, :params => [ :name, :child => [ :name, :child => [ :name ] ] ] do
        result = [params, original_params]
        ''
      end
    end
    post '/basic?' + @jack_query
    assert_equal(
      [
        { 'name' => @jack['name'], 'child' => { 'name' => @kim['name'], 'child' => { 'name' => @teri['name'] } } },
        @jack
      ],
      result
    )
  end

  it 'should be able to process the data' do
    result = nil
    mock_app do
      post :basic, :params => [ :name, :position => proc{ |v| 'anti-'+v } ] do
        result = params
        ''
      end
    end
    post '/basic?' + @jack_query
    assert_equal({ 'name' => @jack['name'], 'position' => 'anti-terrorist' }, result)
  end

  it 'should pass :with parameters' do
    result = nil
    mock_app do
      post :basic, :with => [:id, :tag], :params => [ :name ] do
        result = params
        ''
      end
    end
    post '/basic/24/42?' + @jack_query
    assert_equal({ 'name' => @jack['name'], 'id' => '24', 'tag' => '42' }, result)
  end

  it 'should not fail if :with is not an Array' do
    result = nil
    mock_app do
      post :basic, :with => :id, :params => [ :id ] do
        result = params
        ''
      end
    end
    post '/basic/24?' + @jack_query
    assert_equal({ 'id' => '24' }, result)
  end

  it 'should understand true or false values' do
    result = nil
    mock_app do
      get :hide, :with => [ :id ], :params => false do
        result = params
        ''
      end
      get :show, :with => [ :id ], :params => true do
        result = params
        ''
      end
    end
    get '/hide/1?' + @jack_query
    assert_equal({"id"=>"1"}, result)
    get '/show/1?' + @jack_query
    assert_equal({"id"=>"1"}.merge(@jack), result)
  end

  it 'should be configurable with controller options' do
    result = nil
    mock_app do
      controller :persons, :params => [ :name ] do
        post :create, :params => [ :name, :position ] do
          result = params
          ''
        end
        post :update, :with => [ :id ] do
          result = params
          ''
        end
        post :delete, :params => true do
          result = params
          ''
        end
        post :destroy, :with => [ :id ], :params => false do
          result = params
          ''
        end
      end
      controller :noparam, :params => false do
        get :index do
          result = params
          ''
        end
      end
    end
    post '/persons/create?' + @jack_query
    assert_equal({ 'name' => @jack['name'], 'position' => 'terrorist' }, result)
    post '/persons/update/1?name=Chloe+O\'Brian&position=hacker'
    assert_equal({ 'id' => '1', 'name' => 'Chloe O\'Brian' }, result)
    post '/persons/delete?' + @jack_query
    assert_equal(@jack, result)
    post '/persons/destroy/1?' + @jack_query
    assert_equal({"id"=>"1"}, result)
    get '/noparam?a=1;b=2'
    assert_equal({}, result)
  end

  it 'should successfully filter hashes' do
    result = nil
    mock_app do
      post :family, :params => [ :persons => [ :name ] ] do
        result = params
        ''
      end
    end
    post '/family?' + Padrino::Utils.build_uri_query(@family)
    assert_equal({"persons" => {"3" => {"name" => @jack["name"]}, "2" => {"name" => @kim["name"]}, "1" => {"name" => @teri["name"]}}}, result)
  end

  it 'should pass arrays' do
    result = nil
    mock_app do
      post :family, :params => [ :names => [] ] do
        result = params
        ''
      end
    end
    post '/family?' + Padrino::Utils.build_uri_query(:names => %w{Jack Kim Teri})
    assert_equal({"names" => %w[Jack Kim Teri]}, result)
  end

  it 'should tolerate weird inflections' do
    result = nil
    mock_app do
      post :i, :params => [ :gotta => [ :what ] ] do
        result = params
        ''
      end
    end
    post '/i?' + Padrino::Utils.build_uri_query(:gotta => { :what => 'go', :who => 'self' })
    assert_equal({"gotta" => {"what" => "go"}}, result)
  end

  it 'should drop the key if the data type does not match route configuration' do
    result = nil
    mock_app do
      post :i, :params => [ :gotta => [ :what ] ] do
        result = params
        ''
      end
    end
    post '/i?gotta=go'
    assert_equal({}, result)
  end
end
