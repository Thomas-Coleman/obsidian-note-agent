class User < ApplicationRecord
  has_many :captures, dependent: :destroy
  has_many :templates, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :api_token, presence: true, uniqueness: true
  validates :obsidian_vault_path, presence: true
  
  before_validation :generate_api_token, on: :create
  
  private
  
  def generate_api_token
    self.api_token ||= SecureRandom.base58(32)
  end
end