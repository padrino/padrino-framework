require File.expand_path('../helper', __FILE__)
require 'padrino-helpers'

describe "Padrino::Access" do
  module Character
    extend self
    def authenticate(credentials)
      case
      when credentials[:email] && credentials[:password]
        target = all.find{ |c| c.id.to_s == credentials[:email] }
        target.name.gsub(/[^A-Z]/,'') == credentials[:password] ? target : nil
      when credentials.has_key?(:session_id)
        all.find{ |c| c.id == credentials[:session_id] }
      else
        puts credentials
        false
      end
    end
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
  before do
    mock_app do
      set :credentials_accessor, :visitor
      set :login_model, :character
      register Padrino::Rendering
      enable :sessions
      register Padrino::Login
      get(:index){ 'index' }
      get(:restricted){ 'secret' }
      helpers Padrino::Helpers::AssetTagHelpers
      helpers Padrino::Helpers::OutputHelpers
      helpers Padrino::Helpers::TagHelpers
      helpers Padrino::Helpers::FormHelpers
      helpers do
        def authorized?
          return !['/restricted'].include?(request.env['PATH_INFO']) unless visitor
          case 
          when visitor.id == :bender
            true
          else
            false            
          end
        end
      end
    end
    Character.all.each do |user|
      instance_variable_set :"@#{user.id}", user
    end
  end

  should 'pass unrestricted area' do
    get '/'
    assert_equal 200, status
  end

  should 'be redirected from restricted area to login page' do
    get '/restricted'
    assert_equal 302, status
    get response.location
    assert_equal 200, status
    assert_match /<form .*<input .*/, body
  end

  should 'not be able to authenticate with wrong password' do
    post '/login', :email => :bender, :password => '123'
    assert_equal 200, status
    assert_match 'Wrong password', body
  end

  should 'be able to authenticate with email and password' do
    post '/login', :email => :bender, :password => 'BBR'
    assert_equal 302, status
  end

  should 'be redirected back' do
    get '/restricted'
    post response.location, :email => :bender, :password => 'BBR'
    assert_match /\/restricted$/, response.location
  end

  should 'be redirected to root if no location was saved' do
    post '/login', :email => :bender, :password => 'BBR'
    assert_match /\/$/, response.location
  end

  should 'be allowed in restricted area after logging in' do
    post '/login', :email => :bender, :password => 'BBR'
    get '/restricted'
    assert_equal 'secret', body
  end

  should 'not be allowed in restricted area after logging in an account lacking privileges' do
    post '/login', :email => :leela, :password => 'TL'
    get '/restricted'
    assert_equal 403, status
  end
end
