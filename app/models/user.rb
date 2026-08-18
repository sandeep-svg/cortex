class User < ApplicationRecord
  ROLES = %w[user admin].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :queries, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, allow_nil: true
  validates :role, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end

  def user?
    role == "user"
  end
end
