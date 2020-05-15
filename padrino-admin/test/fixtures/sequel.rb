require 'digest/sha1'
require 'sequel'
require 'sequel/extensions/migration'

Sequel::Model.db = 
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    require 'jdbc/sqlite3' 
    Sequel.connect("jdbc:sqlite::memory:")
  else
    require 'sqlite3'
    Sequel.sqlite(":memory:")
  end

migration = Sequel.migration do
  up do
    create_table :accounts do
      primary_key :id
      String :name
      String :surname
      String :email
      String :crypted_password
      String :role
    end

    create_table :sections do
      primary_key :id
      foreign_key :account_id
      String :name
    end

    create_table :friends do
      primary_key :id
      String :name
      String :age
      String :email
    end

    create_table :pages do
      primary_key :id
      String :name
      String :body
    end
  end

  down do
    drop_table :accounts
  end
end

migration.apply(Sequel::Model.db, :up)

class Friend < Sequel::Model
end

class Page < Sequel::Model
end

# Fake Section Model
class Section < Sequel::Model
  many_to_one :account
end

# Fake Account Model
class Account < Sequel::Model
  attr_accessor :password, :password_confirmation

  one_to_many :sections

  def self.admin;  first(:role => "admin");  end
  def self.editor; first(:role => "editor"); end

  ##
  # Replace ActiveRecord method.
  #
  def self.find_by_id(id)
    self[id] rescue nil
  end
end

# We build some fake accounts
admin  = Account.create(:name => "DAddYE", :role => "admin",  :email => "d.dagostino@lipsiasoft.com",
                        :password => "some", :password_confirmation => "some")
editor = Account.create(:name => "Dexter", :role => "editor", :email => "editor@lipsiasoft.com",
                        :password => "some", :password_confirmation => "some")

%w(News Press HowTo).each do |c|
  admin.add_section(:name => c)
  editor.add_section(:name => c)
end
