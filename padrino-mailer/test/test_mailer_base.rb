require File.dirname(__FILE__) + '/helper'

class DemoMailer < Padrino::Mailer::Base
  def sample_mail
    from 'test@default.com'
    cc 'foo@bar.com'
    bcc 'bar@foo.com'
    to 'test@test.com'
    reply_to 'foobar@foobar.com'
    body "Hello world!"
    via :sendmail
  end

  def sample_mail_smtp
    from 'test@default.com'
    to 'test@test.com'
    body "SMTP Hello world!"
  end
end

class TestMailerBase < Test::Unit::TestCase
  include Padrino::Mailer

  context 'for defining email attributes' do
    DemoMailer.mail_fields.each do |field|
      should "support setting '#{field}' attribute" do
        demo_mailer = DemoMailer.new(:sample_mail)
        demo_mailer.send(field, "some_value")
        assert_equal({ field => "some_value" }, demo_mailer.mail_attributes)
      end
    end

    should "allow defining text body" do
      demo_mailer = DemoMailer.new(:sample_mail)
      demo_mailer.body("Hello world!")
      assert_equal({ :body => "Hello world!" }, demo_mailer.mail_attributes)
    end
  end

  context 'for retrieving template path' do
    should "return correct path" do
      demo_mailer = DemoMailer.new(:sample_mail)
      assert_match %r{demo_mailer/sample_mail.erb}, demo_mailer.template_path
    end
  end

  context 'for #deliver class method' do
    should "perform the email delivery for sendmail" do
      Delivery.expects(:mail).with(:from => 'test@default.com', :to => 'test@test.com', :body => "Hello world!", :via => :sendmail,
                                   :cc => 'foo@bar.com', :bcc => 'bar@foo.com', :reply_to => 'foobar@foobar.com')
      DemoMailer.deliver(:sample_mail)
    end

   should "perform the email delivery for smtp" do
      DemoMailer.smtp_settings = { :host => 'smtp.arcadic.com' }
      Delivery.expects(:mail).with(:from => 'test@default.com', :to => 'test@test.com', 
                               :body => "SMTP Hello world!", :via => :smtp, :smtp => { :host => 'smtp.arcadic.com' })
      DemoMailer.deliver(:sample_mail_smtp)
    end
  end

  context 'for #respond_to? class method' do
    should "respond as true for any delivery method calls for mails that exist" do
      assert DemoMailer.respond_to?(:deliver_sample_mail)
    end

    should "respond as false for any delivery method calls for mails that don't exist" do
      assert_equal false, DemoMailer.respond_to?(:deliver_faker_mail)
    end

    should "respond as true for any non-delivery methods that exist" do
      assert DemoMailer.respond_to?(:inspect)
    end

    should "respond as false for any non-delivery methods that don't exist" do
      assert_equal false, DemoMailer.respond_to?(:fake_method)
    end
  end

  context 'for #method_missing dynamic delivery' do
    should 'invoke deliver method with appropriate parameters' do
      DemoMailer.expects(:deliver).with("example_name", "test", 5)
      DemoMailer.deliver_example_name("test", 5)
    end
  end
end