class Account < Ohm::Model
  attr_accessor :password, :password_confirmation

  # Keys
  attribute :name
  attribute :surname
  attribute :email
  attribute :crypted_password
  attribute :role

  index  :email
  unique :email

  # Validations
  def validate
    assert_present  :email
    assert_present  :role
    if password_required
      assert_present :password
      assert_present :password_confirmation
      assert_length  :password, 4..40
      assert self.password == self.password_confirmation, [:password_not_confirmed]
    end
    assert_email :email
    assert_format :role, /[A-Za-z]/
  end

  # Callbacks
  def save!
    encrypt_password
    super
  end

  ##
  # This method is for authentication purpose.
  #
  def self.authenticate(email, password)
    account = with(:email, email) if email.present?
    account && account.has_password?(password) ? account : nil
  end

  ##
  # This method is used by AuthenticationHelper.
  #
  def self.find_by_id(id)
    self[id]
  end

  ##
  # This method is used by Admin Sessions Controller for login bypass.
  #
  def self.first
    first_id = key[:all].sort(:order => "asc", :limit => [0,1]).first
    self[first_id] if first_id
  end

  def has_password?(password)
    ::BCrypt::Password.new(crypted_password) == password
  end

  private

  def encrypt_password
    self.crypted_password = ::BCrypt::Password.create(password)  if password_required
  end

  def password_required
    crypted_password.blank? || password.present?
  end
end
