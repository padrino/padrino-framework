require File.expand_path('../helper', __FILE__)

Account = Character

describe "Padrino::Auth" do
  before do
    mock_app do
      enable :sessions
      register Padrino::Access
      register Padrino::Login
      get(:robot_area){ 'robot_area' }
      set_access :robots, :allow => :robot_area
    end
  end

  should 'login and access play nicely together' do
    post '/login', :email => :bender, :password => 'BBR'
    get '/robot_area'
    assert_equal 200, status

    post '/login', :email => :leela, :password => 'TL'
    get '/robot_area'
    assert_equal 403, status
  end
end
