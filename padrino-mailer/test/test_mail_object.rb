require File.dirname(__FILE__) + '/helper'

class TestMailObject < Test::Unit::TestCase
  include Padrino::Mailer

  context 'for #deliver method' do
    should "send mail with attributes default to sendmail no smtp" do
      mail_object = Padrino::Mailer::MailObject.new(:to => "test@john.com", :from => "sender@sent.com", :body => "Hello")
      Delivery.expects(:mail).with(:to => "test@john.com", :from => "sender@sent.com", :body => "Hello", :via => :sendmail)
      mail_object.deliver
    end

    should "send mail with attributes default to smtp if set" do
      mail_object = Padrino::Mailer::MailObject.new({:to => "test@john.com", :body => "Hello"}, { :host => 'smtp.gmail.com' })
      Delivery.expects(:mail).with(:to => "test@john.com", :body => "Hello", :via => :smtp, :smtp => { :host => 'smtp.gmail.com' })
      mail_object.deliver
    end

    should "send mail with attributes use sendmail if explicit" do
      mail_object = Padrino::Mailer::MailObject.new({:to => "test@john.com", :via => :sendmail }, { :host => 'smtp.gmail.com' })
      Delivery.expects(:mail).with(:to => "test@john.com", :via => :sendmail)
      mail_object.deliver
    end
  end
end