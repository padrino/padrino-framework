require 'helper'

class TestMongoMapper < Test::Unit::TestCase

  def setup
    load_fixture 'mongo_mapper'
  end

  context 'for mongomapper functionality' do

    should 'check required fields' do
      account = Account.create
      assert ! account.valid?
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