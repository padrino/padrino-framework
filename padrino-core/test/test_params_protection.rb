require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Padrino::ParamsProtection" do
  before do
    @teri = { 'name' => 'Teri Bauer', 'position' => 'baby' }
    @kim = { 'name' => 'Kim Bauer', 'position' => 'daughter', 'child' => @teri }
    @jack = { 'name' => 'Jack Bauer', 'position' => 'terrorist', 'child' => @kim }
  end

  it 'should drop all parameters except allowed ones' do
    result = nil
    mock_app do
      post :basic, :allow => [ :name ] do
        result = params
        ''
      end
    end
    post '/basic?' + @jack.to_query
    assert_equal({ 'name' => @jack['name'] }, result)
  end

  it 'should preserve original params' do
    result = nil
    mock_app do
      post :basic, :allow => [ :name ] do
        result = original_params
        ''
      end
    end
    post '/basic?' + @jack.to_query
    assert_equal(@jack, result)
  end

  it 'should work with recursive data' do
    result = nil
    mock_app do
      post :basic, :allow => [ :name, :child => [ :name, :child => [ :name ] ] ] do
        result = [params, original_params]
        ''
      end
    end
    post '/basic?' + @jack.to_query
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
      post :basic, :allow => [ :name, :position => proc{ |v| 'anti-'+v } ] do
        result = params
        ''
      end
    end
    post '/basic?' + @jack.to_query
    assert_equal({ 'name' => @jack['name'], 'position' => 'anti-terrorist' }, result)
  end

  it 'should pass :with parameters' do
    result = nil
    mock_app do
      post :basic, :with => [:id, :tag], :allow => [ :name ] do
        result = params
        ''
      end
    end
    post '/basic/24/42?' + @jack.to_query
    assert_equal({ 'name' => @jack['name'], 'id' => '24', 'tag' => '42' }, result)
  end

  it 'should be configurable with controller options' do
    result = nil
    mock_app do
      controller :persons, :allow => [ :name ] do
        post :create, :allow => [ :name, :position ] do
          result = params
          ''
        end
        post :update, :with => [ :id ] do
          result = params
          ''
        end
      end
    end
    post '/persons/create?' + @jack.to_query
    assert_equal({ 'name' => @jack['name'], 'position' => 'terrorist' }, result)
    post '/persons/update/1?name=Chloe+O\'Brian&position=hacker'
    assert_equal({ 'id' => '1', 'name' => 'Chloe O\'Brian' }, result)
  end

  it 'should not touch GET params when configured with controller' do
    result = nil
    mock_app do
      controller :persons, :allow => [ :name ] do
        get :show, :with => [ :id ] do
          result = params
          ''
        end
      end
    end
    get '/persons/show/1?name=Chloe+O\'Brian&position=hacker'
    assert_equal({ 'id' => '1', 'name' => 'Chloe O\'Brian', 'position' => 'hacker' }, result)
  end
end
