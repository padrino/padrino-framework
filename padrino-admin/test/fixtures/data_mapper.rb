require 'jdbc/sqlite3' if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
require 'digest/sha1'

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
  include DataMapper::Validate
  attr_accessor :password, :password_confirmation

  # Properties
  property :id,               Serial
  property :name,             String
  property :surname,          String
  property :email,            String
  property :crypted_password, String
  property :salt,             String
  property :role,             String

  has n, :categories
  def self.admin;  first(:role => "admin");  end
  def self.editor; first(:role => "editor"); end

  ##
  # This method is used from AuthenticationHelper
  #
  def self.find_by_id(id)
    get(id)
  end
end

DataMapper.auto_migrate!

# We build some fake accounts
admin  = Account.create(:name => "DAddYE", :role => "admin",  :email => "d.dagostino@lipsiasoft.com",
                        :password => "some", :password_confirmation => "some")
editor = Account.create(:name => "Dexter", :role => "editor", :email => "editor@lipsiasoft.com",
                        :password => "some", :password_confirmation => "some")

%w(News Press HowTo).each do |c|
  admin.categories.create(:name => c)
  editor.categories.create(:name => c)
end
