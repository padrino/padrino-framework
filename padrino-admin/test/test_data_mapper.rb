require 'helper'

class TestDataMapper < Test::Unit::TestCase

  def setup
    load_fixture 'data_mapper'
  end

  context 'for datamapper account functionality' do

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

  context 'for data_mapper functionality' do

    should 'have some standard methods' do
      account = Account.new
      assert_respond_to account, :new_record?
      assert_respond_to account, :to_param
      assert_respond_to account, :update_attributes
      assert_respond_to account, :valid?
      assert_respond_to Account, :properties
      assert_respond_to Account, :count
    end

    should 'have category_ids' do
      account = Account.first
      assert_respond_to account, :category_ids
      assert_respond_to account, :category_ids=
      assert_equal [1, 3, 5], account.category_ids
    end

    should 'have errors_keys' do
      account = Account.new
      account.valid?
      assert_equal [:email, :role, :password, :password_confirmation], account.errors_keys
    end

    should 'have columns names' do
      property = Account.properties.first
      assert_respond_to property, :name
      assert_equal :id, property.name
    end

    should 'have table name' do
      assert_equal "accounts", Account.table_name
    end

    should 'have orm defined' do
      assert_equal :datamapper, Account.orm
    end

    should 'search correctly fields' do
      accounts, categories = {}, {}

      Account.auto_migrate!
      Category.auto_migrate!

      %w(gino paoli mario venuti franco).each do |name|
        accounts[name] = Account.create(:email => "#{name}@foo.com", :role => name, :password => "some", :password_confirmation => "some")
        assert_equal [accounts[name]], Account.ext_search(:query => name, :fields => "email,role").records
        accounts
      end

      %w(rock soul classic rap jazz).each_with_index do |name, i|
        categories[name] = Category.create(:name => name, :account_id => i+1)
        assert_equal [categories[name]], Category.ext_search(:query => name, :fields => "name").records
        accounts
      end

      # Make sure that our builtin count is correct
      assert_equal 5, Account.ext_search({}).count
      assert_equal 5, Account.ext_search({}).count

      # Perform some search
      assert_equal [accounts["venuti"]], Account.ext_search(:query => "en", :fields => "email,role").records
      assert_equal [accounts["gino"], accounts["venuti"], accounts["franco"]], Account.ext_search(:query => "n", :fields => "email,role").records
      assert_equal [accounts["venuti"], accounts["franco"]], Account.ext_search(:start => 3, :limit => 2).records
      assert_equal [accounts["paoli"], accounts["venuti"]],  Account.ext_search(:start => 3, :limit => 2, :sort => "role", :dir => "asc").records

      # Perform some extended search
      # TODO: find a way for fix this DM issue.
      assert_equal [accounts["venuti"]], Account.ext_search({ :query => "rap", :fields => "categories.name" }, :links => [Account.relationships[:categories].inverse]).records
      assert_equal [accounts["franco"], accounts["mario"]], Account.ext_search({:start => 3, :limit => 2, :sort => "categories.name", :dir => "desc"}, :links => [Account.relationships[:categories].inverse]).records
    end
  end
end