require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/fixtures/mongo_mapper'

class TestMongoMapper < Test::Unit::TestCase

  context 'for mongomapper functionality' do

    should 'check required fields' do
      account = MmAccount.create
      assert ! account.valid?
    end

    should 'correctly create an account' do
      account = MmAccount.create(:email => "jack@metal.org", :role => "some", :password => "some", :password_confirmation => "some")
      assert account.valid?
    end

    should 'correctly authenticate an account' do
      account = MmAccount.create(:email => "auth@lipsia.org", :role => "some", :password => "some", :password_confirmation => "some")
      assert_equal "some", account.password_clean
      account_r = MmAccount.authenticate("auth@lipsia.org", "some")
      assert_equal account_r, account
    end
  end
end