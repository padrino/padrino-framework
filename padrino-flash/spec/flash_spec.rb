require File.expand_path('../spec', __FILE__)

describe Padrino::Flash do
  it 'can set the future flash' do
    post '/flash', { :notice => 'Flash' }
    post '/flash', { :success => 'Flash' }
    last_response.body.should == '{:notice=>"Flash"}'
  end

  it 'knows the future flash' do
    post '/flash', { :notice => 'Flash' }
    get '/flash'
    last_response.body.should == '{:notice=>"Flash"}'
  end
end