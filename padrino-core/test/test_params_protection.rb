require_relative 'helper'

describe 'Padrino::ParamsProtection' do
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
      post :basic, params: [:name] do
        result = params
        ''
      end
    end
    post "/basic?#{@jack_query}"
    assert_equal({ 'name' => @jack['name'] }, result)
  end

  it 'should preserve original params' do
    result = nil
    mock_app do
      post :basic, params: [:name] do
        result = original_params
        ''
      end
    end
    post "/basic?#{@jack_query}"
    assert_equal(@jack, result)
  end

  it 'should work with recursive data' do
    result = nil
    mock_app do
      post :basic, params: [:name, { child: [:name, { child: [:name] }] }] do
        result = [params, original_params]
        ''
      end
    end
    post "/basic?#{@jack_query}"
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
      post :basic, params: [:name, { position: proc { |v| "anti-#{v}" } }] do
        result = params
        ''
      end
    end
    post "/basic?#{@jack_query}"
    assert_equal({ 'name' => @jack['name'], 'position' => 'anti-terrorist' }, result)
  end

  it 'should pass :with parameters' do
    result = nil
    mock_app do
      post :basic, with: %i[id tag], params: [:name] do
        result = params
        ''
      end
    end
    post "/basic/24/42?#{@jack_query}"
    assert_equal({ 'name' => @jack['name'], 'id' => '24', 'tag' => '42' }, result)
  end

  it 'should not fail if :with is not an Array' do
    result = nil
    mock_app do
      post :basic, with: :id, params: [:id] do
        result = params
        ''
      end
    end
    post "/basic/24?#{@jack_query}"
    assert_equal({ 'id' => '24' }, result)
  end

  it 'should understand true or false values' do
    result = nil
    mock_app do
      get :hide, with: [:id], params: false do
        result = params
        ''
      end
      get :show, with: [:id], params: true do
        result = params
        ''
      end
    end
    get "/hide/1?#{@jack_query}"
    assert_equal({ 'id' => '1' }, result)
    get "/show/1?#{@jack_query}"
    assert_equal({ 'id' => '1' }.merge(@jack), result)
  end

  it 'should be configurable with controller options' do
    result = nil
    mock_app do
      controller :persons, params: [:name] do
        post :create, params: %i[name position] do
          result = params
          ''
        end
        post :update, with: [:id] do
          result = params
          ''
        end
        post :delete, params: true do
          result = params
          ''
        end
        post :destroy, with: [:id], params: false do
          result = params
          ''
        end
      end
      controller :noparam, params: false do
        get :index do
          result = params
          ''
        end
      end
    end
    post "/persons/create?#{@jack_query}"
    assert_equal({ 'name' => @jack['name'], 'position' => 'terrorist' }, result)
    post '/persons/update/1?name=Chloe+O\'Brian&position=hacker'
    assert_equal({ 'id' => '1', 'name' => 'Chloe O\'Brian' }, result)
    post "/persons/delete?#{@jack_query}"
    assert_equal(@jack, result)
    post "/persons/destroy/1?#{@jack_query}"
    assert_equal({ 'id' => '1' }, result)
    get '/noparam?a=1;b=2'
    assert_empty(result)
  end

  it 'should successfully filter hashes' do
    result = nil
    mock_app do
      post :family, params: [persons: [:name]] do
        result = params
        ''
      end
    end
    post "/family?#{Padrino::Utils.build_uri_query(@family)}"
    assert_equal({ 'persons' => { '3' => { 'name' => @jack['name'] }, '2' => { 'name' => @kim['name'] }, '1' => { 'name' => @teri['name'] } } }, result)
  end

  it 'should pass arrays' do
    result = nil
    mock_app do
      post :family, params: [names: []] do
        result = params
        ''
      end
    end
    post "/family?#{Padrino::Utils.build_uri_query(names: %w[Jack Kim Teri])}"
    assert_equal({ 'names' => %w[Jack Kim Teri] }, result)
  end

  it 'should tolerate weird inflections' do
    result = nil
    mock_app do
      post :i, params: [gotta: [:what]] do
        result = params
        ''
      end
    end
    post "/i?#{Padrino::Utils.build_uri_query(gotta: { what: 'go', who: 'self' })}"
    assert_equal({ 'gotta' => { 'what' => 'go' } }, result)
  end

  it 'should drop the key if the data type does not match route configuration' do
    result = nil
    mock_app do
      post :i, params: [gotta: [:what]] do
        result = params
        ''
      end
    end
    post '/i?gotta=go'
    assert_empty(result)
  end

  it 'should filter each hash of an array with the nested list' do
    result = nil
    mock_app do
      post :family, params: [{ persons: [:name, { age: Integer }] }] do
        result = params
        ''
      end
    end
    post '/family?persons[][name]=Jack&persons[][position]=agent&persons[][age]=50&persons[][name]=Kim'
    assert_equal({ 'persons' => [{ 'name' => 'Jack', 'age' => 50 }, { 'name' => 'Kim' }] }, result)
  end

  it 'should keep only the elements of an array that match the nested list' do
    result = nil
    mock_app do
      post :family, params: [{ persons: [:name] }, { names: [] }] do
        result = params
        ''
      end
    end
    post '/family?persons[]=Jack&persons[][name]=Kim&names[]=Teri&names[][name]=Chloe'
    assert_equal({ 'persons' => [{ 'name' => 'Kim' }], 'names' => ['Teri'] }, result)
    post '/family?persons[][]=Jack&names[][]=Teri'
    assert_equal({ 'persons' => [], 'names' => [] }, result)
  end

  it 'should drop an array or a hash given for an Integer' do
    result = nil
    mock_app do
      post :basic, params: [{ id: Integer }] do
        result = params
        ''
      end
    end
    post '/basic?id[]=1&id[]=2'
    assert_empty(result)
    post '/basic?id[a]=1'
    assert_empty(result)
    post '/basic?id=3'
    assert_equal({ 'id' => 3 }, result)
  end

  it 'should cast an Integer given without a value to nil' do
    result = nil
    mock_app do
      post :basic, params: [{ id: Integer }] do
        result = params
        ''
      end
    end
    post '/basic?id'
    assert_equal({ 'id' => nil }, result)
  end

  it 'should drop the entries of a collection that are not hashes' do
    result = nil
    mock_app do
      post :family, params: [{ persons: [:name] }] do
        result = params
        ''
      end
    end
    post '/family?persons[1][name]=Jack&persons[1][position]=agent&persons[2]=Kim'
    assert_equal({ 'persons' => { '1' => { 'name' => 'Jack' } } }, result)
  end

  it 'should call a proc with an array value' do
    result = nil
    mock_app do
      post :family, params: [{ names: proc { |v| Array(v).join(',') } }] do
        result = params
        ''
      end
    end
    post '/family?names[]=Jack&names[]=Kim'
    assert_equal({ 'names' => 'Jack,Kim' }, result)
  end

  it 'should keep the type given for a :with parameter' do
    result = nil
    mock_app do
      get :show, with: :id, params: [:name, { id: Integer }] do
        result = params
        ''
      end
      controller :persons, params: [:name, { id: Integer }] do
        get :edit, with: :id do
          result = params
          ''
        end
      end
    end
    get '/show/24?name=Jack&position=agent'
    assert_equal({ 'name' => 'Jack', 'id' => 24 }, result)
    get '/persons/edit/42?name=Kim&position=daughter'
    assert_equal({ 'name' => 'Kim', 'id' => 42 }, result)
  end

  it 'should keep the path captures of a route with a params list' do
    result = nil
    mock_app do
      controller :posts, params: [:title] do
        controller :comments, parent: :post do
          get(:index) { result = params; '' }
        end
      end
      controller :notes, parent: :post, params: [:title] do
        get(:index) { result = params; '' }
      end
      get(:list, map: '/c/:cid/list', params: [:title]) { result = params; '' }
    end
    get '/post/7/comments?title=t&x=1'
    assert_equal({ 'title' => 't', 'post_id' => '7' }, result)
    get '/post/8/notes?title=t&x=1'
    assert_equal({ 'title' => 't', 'post_id' => '8' }, result)
    get '/c/9/list?title=t&x=1'
    assert_equal({ 'title' => 't', 'cid' => '9' }, result)
  end

  it 'should keep an Integer given for an Integer' do
    result = nil
    mock_app do
      post(:create, params: [{ id: Integer }]) { result = params; '' }
    end
    input = StringIO.new(''.b)
    post '/create', {}, 'rack.input' => input, 'rack.request.form_input' => input, 'rack.request.form_hash' => { 'id' => 5 }
    assert_equal({ 'id' => 5 }, result)
  end

  it 'should filter the routes of a nested controller with the outer list' do
    result = nil
    mock_app do
      controller :persons, params: [:name] do
        controller :children do
          get(:index) { result = params; '' }
        end
        controller :parents, params: [:position] do
          get(:index) { result = params; '' }
        end
        controller :all, params: true do
          get(:index) { result = params; '' }
        end
        get(:index) { result = params; '' }
      end
      get(:top) { result = params; '' }
    end
    get "/children?#{@jack_query}"
    assert_equal({ 'name' => @jack['name'] }, result)
    get "/parents?#{@jack_query}"
    assert_equal({ 'position' => @jack['position'] }, result)
    get "/all?#{@jack_query}"
    assert_equal(@jack, result)
    get "/persons?#{@jack_query}"
    assert_equal({ 'name' => @jack['name'] }, result)
    get "/top?#{@jack_query}"
    assert_equal(@jack, result)
  end
end
