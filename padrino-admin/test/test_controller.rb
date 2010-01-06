require 'helper'

class TestController < Test::Unit::TestCase

  def setup
    load_fixture 'data_mapper'
    @column_store = Padrino::ExtJs::Controller.column_store_for(Account) do |cm|
      cm.add :name.upcase,  "Name Upcase",     :sortable => true, :dataIndex => :name
      cm.add :surname  # Not exist but it's not a problem
      cm.add :category.name
      cm.add :email,        "E-Mail",         :sortable => true
      cm.add :role,                           :sortable => true
    end
  end

  should 'have correct column fileds' do
    assert_equal nil, @column_store.column_fields
  end

  should 'have correct store fields' do
    assert_equal nil, @column_store.store_fields
  end

  should 'store data' do
    assert_equal nil, @column_store.store_data(:fields => "name,role", :query => "d", :sort => :name, :dir => :asc, :limit => 2, :offset => 0)
  end

end