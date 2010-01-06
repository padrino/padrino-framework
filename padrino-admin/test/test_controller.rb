require 'helper'

class TestController < Test::Unit::TestCase

  def setup
    load_fixture 'data_mapper'
    config = Padrino::ExtJs::Config.load <<-YAML
      columns:
        - method: name.upcase
          header: Name Upcase
          dataIndex: name
        - method: surname
        - method: category.name
        - method: email
          header: E-mail
          sortable: false
        - method: role
    YAML
    @column_store = Padrino::ExtJs::Controller.column_store_for(Account, config)
  end

  should 'have correct column fileds' do
    result = [
      {"name"=>"account[name]",
       "sortable"=>true,
       "header"=>"Name upcase",
       "id"=>"account_name",
       "dataIndex"=>"accounts.name"},
      {"name"=>"account[surname]",
       "sortable"=>true,
       "header"=>"Surname",
       "id"=>"account_surname",
       "dataIndex"=>"accounts.surname"},
      {"name"=>"category[name]",
       "sortable"=>true,
       "header"=>"Category.name",
       "id"=>"category_name",
       "dataIndex"=>"category.name"},
      {"name"=>"account[email]",
       "sortable"=>false,
       "header"=>"E-mail",
       "id"=>"account_email",
       "dataIndex"=>"accounts.email"},
      {"name"=>"account[role]",
       "sortable"=>true,
       "header"=>"Role",
       "id"=>"account_role",
       "dataIndex"=>"accounts.role"}]
    assert_equal result, @column_store.column_fields
  end

  should 'have correct store fields' do
    result = [
      {:mapping=>"account_name", :name=>"accounts.name"},
      {:mapping=>"account_surname", :name=>"accounts.surname"},
      {:mapping=>"category_name", :name=>"category.name"},
      {:mapping=>"account_email", :name=>"accounts.email"},
      {:mapping=>"account_role", :name=>"accounts.role"}]
    assert_equal result, @column_store.store_fields
  end

  should 'store data' do
    result = {:results=>[
      {"account_surname"=>"Not found",
       "account_email"=>"d.dagostino@lipsiasoft.com",
       "category_name"=>"Not found",
       "id"=>1,
       "account_role"=>"Admin",
       "account_name"=>"DADDYE"},
      {"account_surname"=>"Not found",
       "account_email"=>"editor@lipsiasoft.com",
       "category_name"=>"Not found",
       "id"=>2,
       "account_role"=>"Editor",
       "account_name"=>"DEXTER"}], :count=>2}
    assert_equal result, @column_store.store_data(:fields => "name,role", :query => "d", :sort => :name, :dir => :asc, :limit => 2, :offset => 0)
  end

end