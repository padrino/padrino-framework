require 'sinatra/base'
require 'haml'

class MailerDemo < Sinatra::Base
  configure do
    set :root, File.dirname(__FILE__)
    set :smtp_settings, {
      :host   => 'smtp.gmail.com',
      :port   => '587',
      :tls    => true,
      :user   => 'user',
      :pass   => 'pass',
      :auth   => :plain
    }
  end

  register Padrino::Mailer

  class SampleMailer < Padrino::Mailer::Base
    def birthday_message(name, age)
      subject "Happy Birthday!"
      to   'john@fake.com'
      from 'noreply@birthday.com'
      body 'name' => name, 'age' => age
      via  :smtp
    end

    def anniversary_message(names, years_married)
      subject "Happy anniversary!"
      to   'julie@fake.com'
      from 'noreply@anniversary.com'
      body 'names' => names, 'years_married' => years_married
      content_type 'text/html'
    end

    def welcome_message(name)
      template 'sample_mailer/foo_message'
      subject "Welcome Message!"
      to   'john@fake.com'
      from 'noreply@custom.com'
      body 'name' => name
      via  :smtp
    end
  end

  post "/deliver/plain" do
    result = SampleMailer.deliver_birthday_message("Joey", 21)
    result ? "mail delivered" : 'mail not delivered'
  end

  post "/deliver/custom" do
    result = SampleMailer.deliver_welcome_message("Bobby")
    result ? "mail delivered" : 'mail not delivered'
  end

  post "/deliver/html" do
    result = SampleMailer.deliver_anniversary_message("Joey & Charlotte", 16)
    result ? "mail delivered" : 'mail not delivered'
  end
end

class MailerUser

end
