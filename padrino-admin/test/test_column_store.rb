require 'helper'

class TestController < Test::Unit::TestCase

  def setup
    load_fixture 'data_mapper'
    config = YAML.load <<-YAML
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
    @column_store = Padrino::Admin::ColumnStore.new(Account, config)
    @column_store_direct = Account.column_store("test/fixtures/test_column_store.jml")
  end

  should 'have correct column fileds' do
    result = "[{\"name\":\"account[name]\",\"header\":\"Name upcase\",\"sortable\":true,\"id\":\"account_name\",\"dataIndex\":\"accounts.name\"},{\"name\":\"account[surname]\",\"header\":\"Surname\",\"sortable\":true,\"id\":\"account_surname\",\"dataIndex\":\"accounts.surname\"},{\"name\":\"category[name]\",\"header\":\"Category.name\",\"sortable\":true,\"id\":\"category_name\",\"dataIndex\":\"category.name\"},{\"name\":\"account[email]\",\"header\":\"E-mail\",\"sortable\":false,\"id\":\"account_email\",\"dataIndex\":\"accounts.email\"},{\"name\":\"account[role]\",\"header\":\"Role\",\"sortable\":true,\"id\":\"account_role\",\"dataIndex\":\"accounts.role\"}]"
    assert_equal result, @column_store.column_fields
    assert_equal result, @column_store_direct.column_fields
  end

  should 'have correct store fields' do
    result = "[{\"mapping\":\"account_name\",\"name\":\"accounts.name\"},{\"mapping\":\"account_surname\",\"name\":\"accounts.surname\"},{\"mapping\":\"category_name\",\"name\":\"category.name\"},{\"mapping\":\"account_email\",\"name\":\"accounts.email\"},{\"mapping\":\"account_role\",\"name\":\"accounts.role\"}]"
    assert_equal result, @column_store.store_fields
    assert_equal result, @column_store_direct.store_fields
  end

  should 'store data' do
    result = "{\"count\":2,\"results\":[{\"account_surname\":\"Not found\",\"account_email\":\"d.dagostino@lipsiasoft.com\",\"category_name\":\"Not found\",\"id\":1,\"account_role\":\"Admin\",\"account_name\":\"DADDYE\"},{\"account_surname\":\"Not found\",\"account_email\":\"editor@lipsiasoft.com\",\"category_name\":\"Not found\",\"id\":2,\"account_role\":\"Editor\",\"account_name\":\"DEXTER\"}]}"
    assert_equal result, @column_store.store_data(:fields => "name,role", :query => "d", :sort => :name, :dir => :asc, :limit => 2, :offset => 0)
    assert_equal result, @column_store_direct.store_data(:fields => "name,role", :query => "d", :sort => :name, :dir => :asc, :limit => 2, :offset => 0)
  end

end