require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestDelivery < Test::Unit::TestCase
  include Padrino::Mailer

  context 'for #deliver method' do
    setup { Mail::Message.any_instance.expects(:deliver!).returns(true).once }
    
    should "send mail with attributes default to sendmail no smtp" do
      Delivery.mail(:to => "test@john.com", :from => "sender@sent.com", :body => "Hello", :via => :sendmail)
    end

    should "send mail with attributes default to smtp if set" do
      Delivery.mail(:to => "test@john.com", :body => "Hello", :via => :smtp, :smtp => { :host => 'smtp.gmail.com' })
    end

    should "send mail with attributes use sendmail if explicit" do
      Delivery.mail(:to => "test@john.com", :via => :sendmail)
    end
  end
end