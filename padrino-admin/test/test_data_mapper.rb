require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/fixtures/data_mapper'

class TestDataMapper < Test::Unit::TestCase

  context 'for datamapper functionality' do

    should 'override default new_record? deprecation' do
      assert Account.new.respond_to?(:new_record?)
    end

    should 'check required fields' do
      errors = Account.create.errors
      assert_equal [:email, :role, :password, :password_confirmation], errors.keys
    end

    should 'correctly create an account' do
      account = Account.create(:email => "jack@metal.org", :role => "some", :password => "some", :password_confirmation => "some")
      assert account.valid?
    end

    should 'correctly authenticate an account' do
      account = Account.create(:email => "auth@lipsia.org", :role => "some", :password => "some", :password_confirmation => "some")
      assert_equal "some", account.password_clean
      account_r = Account.authenticate("auth@lipsia.org", "some")
      assert_equal account_r, account
    end
  end
end