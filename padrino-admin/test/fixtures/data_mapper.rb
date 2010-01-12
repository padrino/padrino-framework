require 'dm-core'
require 'dm-validations'

DataMapper.setup(:default, 'sqlite3::memory:')

# Fake Category Model
class Category
  include DataMapper::Resource
  property :id,   Serial
  property :name, String
  belongs_to :account
end

# Fake Account Model
class Account
  include DataMapper::Resource
  property :id,   Serial
  property :name, String
  has n, :categories
  def self.admin;  first(:role => "Admin");  end
  def self.editor; first(:role => "Editor"); end
end

Padrino::Admin::Adapters.register(:datamapper)
DataMapper.auto_migrate!

# We build some fake accounts
admin  = Account.create(:name => "DAddYE", :role => "Admin",  :email => "d.dagostino@lipsiasoft.com", 
                        :password => "some", :password_confirmation => "some")
editor = Account.create(:name => "Dexter", :role => "Editor", :email => "editor@lipsiasoft.com",
                        :password => "some", :password_confirmation => "some")

%w(News Press HowTo).each do |c| 
  admin.categories.create(:name => c)
  editor.categories.create(:name => c)
end