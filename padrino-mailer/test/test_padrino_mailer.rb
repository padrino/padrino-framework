require File.expand_path(File.dirname(__FILE__) + '/helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/sinatra_app/app')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/padrino_app/app')

describe "PadrinoMailer" do
  describe 'for mail delivery in sample Sinatra application' do
    before { @app = SinatraApp }

    it 'should be able to deliver inline emails using the email helper' do
      post '/deliver/inline'
      assert_equal 'mail delivered', body
      assert_email_sent(:to => 'john@apple.com',
                        :from => 'joe@smith.com',
                        :subject => 'Test Email',
                        :body => 'Test Body',
                        :delivery_method => @app.delivery_method)
    end

    it 'should be able to deliver plain text emails' do
      post '/deliver/plain'
      assert_equal 'mail delivered', body
      assert_email_sent(:to => 'john@fake.com',
                        :from => 'noreply@birthday.com',
                        :delivery_method => @app.delivery_method,
                        :subject => "Happy Birthday!",
                        :body => "Happy Birthday Joey!\nYou are turning 21")
    end

    it 'should be able to deliver emails with custom view' do
      post '/deliver/custom'
      assert_equal 'mail delivered', body
      assert_email_sent(:template => 'mailers/sample/foo_message',
                        :to => 'john@fake.com',
                        :from => 'noreply@custom.com',
                        :delivery_method => @app.delivery_method,
                        :subject => 'Welcome Message!',
                        :body => 'Hello to Bobby')
    end

    it 'should be able to deliver html emails' do
      post '/deliver/html'
      assert_equal 'mail delivered', body
      assert_email_sent(:to => 'julie@fake.com',
                        :from => 'noreply@anniversary.com',
                        :content_type => 'text/html',
                        :delivery_method => @app.delivery_method,
                        :subject => 'Happy anniversary!',
                        :body => "<p>Yay Joey & Charlotte!</p>\n<p>You have been married 16 years</p>")
    end

    it 'should be able to deliver a basic email using app settings' do
      @app.email(:to => 'john@apple.com', :from => 'joe@smith.com',
                 :subject => 'Test Email', :body => 'Test Body',
                 :via => :test)
      assert_email_sent(:to => 'john@apple.com', :from => 'joe@smith.com',
                        :subject => 'Test Email', :body => 'Test Body',
                        :delivery_method => @app.delivery_method)
    end
  end

  describe 'for mail delivery in sample Padrino application' do
    before { @app = PadrinoApp }

    it 'should be able to deliver inline emails using the email helper' do
      post '/deliver/inline'
      assert_equal 'mail delivered', body
      assert_email_sent(:to => 'john@apple.com', :from => 'joe@smith.com',
                        :delivery_method => @app.delivery_method, :subject => 'Test Email',
                        :body => 'Test Body')
    end

    it 'should be able to deliver plain text emails' do
      post '/deliver/plain'
      assert_equal 'mail delivered', body
      assert_email_sent(:to => 'john@fake.com', :from => 'noreply@birthday.com',
                        :delivery_method => @app.delivery_method, :subject => "Happy Birthday!",
                        :body => "Happy Birthday Joey!\nYou are turning 21")
    end

    it 'should be able to deliver emails with custom view' do
      post '/deliver/custom'
      assert_equal 'mail delivered', body
      assert_email_sent(:template => 'mailers/sample/foo_message', :to => 'john@fake.com',
                        :from => 'noreply@custom.com', :delivery_method => @app.delivery_method,
                        :subject => 'Welcome Message!', :body => 'Hello to Bobby')
    end

    it 'should be able to deliver html emails' do
      post '/deliver/html'
      assert_equal 'mail delivered', body
      assert_email_sent(:to => 'julie@fake.com', :from => 'noreply@anniversary.com',
                        :content_type => 'text/html', :delivery_method => @app.delivery_method,
                        :subject => 'Happy anniversary!', :body => "<p>Yay Joey & Charlotte!</p>\n<p>You have been married 16 years</p>")
    end

    it 'should be able to deliver a basic email using app settings' do
      @app.email(:to => 'john@apple.com', :from => 'joe@smith.com',
                 :subject => 'Test Email', :body => 'Test Body',
                 :via => :test)
      assert_email_sent(:to => 'john@apple.com', :from => 'joe@smith.com',
                        :subject => 'Test Email', :body => 'Test Body',
                        :delivery_method => @app.delivery_method)
    end

    it 'should be able to deliver a basic email using Padrino::Helpers' do
      skip #FIXME
      post '/deliver/helper'
      assert_equal 'mail delivered', body
      assert_email_sent(:to => 'jim@fake.com', :from => 'noreply@custom.com',
                        :content_type => 'text/html', :delivery_method => @app.delivery_method,
                        :subject => 'Welcome Helper!', :body => "<a href=\"#\">jim</a>")
    end

    it 'should fail with proper message if mailer is not registered' do
      error = assert_raises RuntimeError do
        post '/deliver/failing_mailer'
      end
      assert_match /is not registered/, error.message
    end

    it 'should fail with proper message if message does not exist' do
      error = assert_raises RuntimeError do
        post '/deliver/failing_message'
      end
      assert_match /has no message/, error.message
    end
  end
end
