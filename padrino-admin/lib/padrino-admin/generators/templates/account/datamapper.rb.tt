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
  validates_present      :email, :role
  validates_present      :password,                          :if => :password_required
  validates_present      :password_confirmation,             :if => :password_required
  validates_length       :password, :min => 4, :max => 40,   :if => :password_required
  validates_is_confirmed :password,                          :if => :password_required
  validates_length       :email,    :min => 3, :max => 100
  validates_is_unique    :email,    :case_sensitive => false
  validates_format       :email,    :with => :email_address
  validates_format       :role,     :with => /[A-Za-z]/

  # Callbacks
  before :save, :generate_password

  ##
  # This method is for authentication purpose
  #
  def self.authenticate(email, password)
    account = first(:conditions => { :email => email }) if email.present?
    account && account.password_clean == password ? account : nil
  end

  ##
  # This method is used from AuthenticationHelper
  #
  def self.find_by_id(id)
    get(id) rescue nil
  end

  ##
  # This method is used for retrive the original password.
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