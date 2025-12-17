class User < ApplicationRecord
  has_many :captures, dependent: :destroy
  has_many :templates, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :api_token, presence: true, uniqueness: true
  validates :obsidian_vault_path, presence: true

  before_validation :generate_api_token, on: :create
  after_initialize :set_default_vault_path, if: :new_record?

  private

  def generate_api_token
    self.api_token ||= SecureRandom.base58(32)
  end

  def set_default_vault_path
    return if obsidian_vault_path.present?

    self.obsidian_vault_path = if Rails.env.production?
      # In production (Docker), use the mounted path inside the container
      "/rails/obsidian_vault"
    else
      # In development, use the local Mac path
      "/Users/tomcoleman/Documents/Obsidian/Tom's Obsidian Notes"
    end
  end
end
