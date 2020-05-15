require 'sinatra/base'

class SinatraApp < Sinatra::Base
  register Padrino::Mailer

  set :root, File.dirname(__FILE__)
  set :delivery_method, :test

  mailer :sample do
    email :birthday do |name, age|
      subject "Happy Birthday!"
      to      'john@fake.com'
      from    'noreply@birthday.com'
      locals  :name => name, :age => age
      via     :test
      render  'sample/birthday'
    end

    email :anniversary do |names, years_married|
      subject "Happy anniversary!"
      to   'julie@fake.com'
      from 'noreply@anniversary.com'
      locals :names => names, :years_married => years_married
      content_type :html
      via  :test
      render 'sample/anniversary'
    end

    message :welcome do |name|
      subject "Welcome Message!"
      to      'john@fake.com'
      from    'noreply@custom.com'
      locals  :name => name
      via     :test
      render  'sample/foo_message'
    end
  end

  post "/deliver/inline" do
    result = email(:to => "john@apple.com", :from => "joe@smith.com", :subject => "Test Email", :body => "Test Body", :via => :test)
    result ? "mail delivered" : 'mail not delivered'
  end

  post "/deliver/plain" do
    result = deliver(:sample, :birthday, "Joey", 21)
    result ? "mail delivered" : 'mail not delivered'
  end

  post "/deliver/html" do
    result = deliver(:sample, :anniversary, "Joey & Charlotte", 16)
    result ? "mail delivered" : 'mail not delivered'
  end

  post "/deliver/custom" do
    result = deliver(:sample, :welcome, "Bobby")
    result ? "mail delivered" : 'mail not delivered'
  end
end
