require File.expand_path('../spec', __FILE__)

describe Padrino::Flash::Storage do
  let :flash do
    Padrino::Flash::Storage.new(session[:_flash])
  end

  before do
    flash[:one] = 'One'
    flash[:two] = 'Two'
  end

  it 'can delete a single flash' do
    flash[:notice].should == 'Flash Notice'
    flash.delete :notice
    flash.key?(:notice).should be_false
    flash[:notice].should be_nil
  end

  it 'can delete the entire flash' do
    flash[:notice].should == 'Flash Notice'
    flash[:success].should == 'Flash Success'
    flash.clear
    flash[:notice].should be_nil
    flash[:success].should be_nil
  end

  it 'should set future flash messages' do
    flash[:future] = 'Test'
    flash[:future].should be_nil
  end

  it 'should allow you to set the present flash' do
    flash.now[:present] = 'Test'
    flash[:present].should == 'Test'
  end

  it 'can discard the entire flash' do
    flash.discard
    flash.sweep
    flash[:one].should_not == 'One'
    flash[:two].should_not == 'Two'
  end

  it 'can discard a single flash' do
    flash.discard :one
    flash.sweep
    flash[:one].should_not == 'One'
    flash[:two].should == 'Two'
  end

  it 'can keep the entire flash' do
    flash.keep
    flash.sweep
    flash[:notice].should == 'Flash Notice'
  end

  it 'can keep a single flash' do
    flash.keep :notice
    flash.sweep
    flash[:notice].should == 'Flash Notice'
    flash[:success].should_not == 'Flash Success'
  end

  it 'can iterate through flash messages' do
    flashes = []
    flash.each do |type, message|
      flashes << [type, message]
    end
    flashes[0].should == [:notice, 'Flash Notice']
    flashes[1].should == [:success, 'Flash Success']
  end

  it 'can sweep up the old to make room for the new' do
    flash[:notice].should == 'Flash Notice'
    flash[:one].should be_nil
    flash.sweep
    flash[:notice].should be_nil
    flash[:one].should == 'One'
  end

  it 'can replace the current flash messages' do
    flash[:notice].should == 'Flash Notice'
    flash.replace(:error => 'Replaced')
    flash[:notice].should be_nil
    flash[:error].should == 'Replaced'
  end

  it 'can return the existing flash keys' do
    flash.keys.should == [:notice, :success]
    flash.keys.should_not include(:one, :two)
  end

  it 'can tell you if a key is set' do
    flash.key?(:notice).should be_true
    flash.key?(:one).should be_false
  end

  it 'can merge flash messages' do
    flash[:notice].should == 'Flash Notice'
    flash.update(:notice => 'Flash Success')
    flash[:notice].should == 'Flash Success'
  end
end