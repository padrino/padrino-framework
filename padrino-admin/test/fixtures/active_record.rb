require 'active_record'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define do
  create_table :accounts, :force => true do |t|
    t.column :id,               :integer
    t.column :name,             :string
    t.column :role,             :string
    t.column :crypted_password, :string
    t.column :salt,             :string
    t.column :email,            :string
  end

  create_table :categories, :force => true do |t|
    t.column :name, :string
    t.column :account_id, :integer
  end
end

class Account < ActiveRecord::Base
  has_many :categories
end

class Category < ActiveRecord::Base
  belongs_to :account
end

Padrino::Admin::Orm.register!