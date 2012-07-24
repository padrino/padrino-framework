require File.expand_path('../spec', __FILE__)

describe Padrino::Flash::Helpers do
  include Padrino::Helpers::OutputHelpers
  include Padrino::Helpers::TagHelpers
  include Padrino::Flash::Helpers

  context '#redirect' do
    it 'should let you to use a string to set a flash message' do
      app.get(:redirect) { redirect('/flash', :notice => 'Redirected') }
      get '/redirect'
      follow_redirect!
      last_response.body.should == '{:notice=>"Redirected"}'
    end

    it 'should localize flash message when a :symbol is used' do
      app.get(:redirect) { redirect('/flash', :notice => :redirected) }
      get '/redirect'
      follow_redirect!
      last_response.body.should == '{:notice=>"Redirected"}'
    end

    it 'should allow you to set multiple flash messages' do
      app.get(:redirect) { redirect('/flash', :notice => 'Redirected', :success => 'Redirected') }
      get '/redirect'
      follow_redirect!
      last_response.body.should == '{:notice=>"Redirected", :success=>"Redirected"}'
    end

    it 'should allow you to set the status code' do
      app.get(:redirect) { redirect('/flash', 301) }
      get '/redirect'
      last_response.status.should == 301
    end

    it 'should allow you to set the status code with flash messages' do
      app.get(:redirect) { redirect('/flash', 301, :notice => 'Redirected') }
      get '/redirect'
      last_response.status.should == 301
      follow_redirect!
      last_response.body.should == '{:notice=>"Redirected"}'
    end
  end

  context '#flash_message' do
    it 'should return the contents of the specified flash' do
      flash = flash_message(:success)
      flash.should have_tag(:div, :count => 1, :with => { :id => 'flash-success', :class => 'success', :title => 'Success' })
    end

    it 'should return nil when the specified flash is not set' do
      flash = flash_message(:error)
      flash.should be_nil
    end
  end

  context '#flash_messages' do
    it 'should return the contents of all flashes' do
      flashes = flash_messages
      flashes.should have_tag(:div, :count => 1, :with => { :id => 'flash' }) do
        with_tag(:span, :text => 'Flash Success', :with => { :class => 'success', :title => 'Success' })
        with_tag(:span, :text => 'Flash Notice', :with => { :class => 'notice', :title => 'Notice' })
      end
    end

    it 'should return an empty div when no flash messages set' do
      session.clear
      flashes = flash_messages
      flashes.should have_tag(:div, :count => 1, :with => { :id => 'flash' })
    end
  end
end