ENV['PADRINO_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

class PadrinoApp < Padrino::Application
  register Padrino::Rendering
  register Padrino::Helpers
  register Padrino::Mailer

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
      content_type :html
      via     :test
      locals  :names => names, :years_married => years_married
      render  'sample/anniversary'
    end

    message :welcome do |name|
      subject "Welcome Message!"
      to      'john@fake.com'
      from    'noreply@custom.com'
      locals  :name => name
      via     :test
      render  'sample/foo_message'
    end

    message :helper do |name|
      subject "Welcome Helper!"
      to      'jim@fake.com'
      from    'noreply@custom.com'
      locals  :name => name
      via     :test
      render  'sample/helper_message'
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

  post "/deliver/helper" do
    result = deliver(:sample, :helper, "Jim")
    result ? "mail delivered" : 'mail not delivered'
  end

end

Padrino.mount("PadrinoApp").to("/")
Padrino.load!
