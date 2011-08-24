require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-aggregates'
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

  # Validations
  validates_presence_of      :email, :role
  validates_presence_of      :password,                          :if => :password_required
  validates_presence_of      :password_confirmation,             :if => :password_required
  validates_length_of        :password, :min => 4, :max => 40,   :if => :password_required
  validates_confirmation_of  :password,                          :if => :password_required
  validates_length_of        :email,    :min => 3, :max => 100
  validates_uniqueness_of    :email,    :case_sensitive => false
  validates_format_of        :email,    :with => :email_address
  validates_format_of        :role,     :with => /[A-Za-z]/

  has n, :categories
  def self.admin;  first(:role => "admin");  end
  def self.editor; first(:role => "editor"); end

  # Callbacks
  before :save, :generate_password

  ##
  # This method it's for authentication purpose
  #
  def self.authenticate(email, password)
    account = first(:conditions => { :email => email }) if email.present?
    account && account.password_clean == password ? account : nil
  end

  ##
  # This method is used from AuthenticationHelper
  #
  def self.find_by_id(id)
    get(id)
  end

  ##
  # This method it's used for retrive the original password.
  #
  def password_clean
    crypted_password.decrypt(salt)
  end

  private
    def generate_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new?
      self.crypted_password = password.encrypt(self.salt)
    end

    def password_required
      crypted_password.blank? || !password.blank?
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
