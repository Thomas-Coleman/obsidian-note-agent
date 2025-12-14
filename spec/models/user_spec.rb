require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:captures).dependent(:destroy) }
    it { should have_many(:templates).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }
    it { should validate_presence_of(:obsidian_vault_path) }

    # Uniqueness validations need a persisted record
    describe 'uniqueness' do
      # Create a fresh user for each uniqueness test
      it 'validates uniqueness of email (case insensitive)' do
        user = create(:user)
        expect(user).to validate_uniqueness_of(:email).case_insensitive
      end
    end
  end

  describe 'callbacks' do
    describe '#generate_api_token' do
      it 'generates an api_token before validation on create' do
        user = User.new(email: 'test@example.com', obsidian_vault_path: '/path')
        expect(user.api_token).to be_nil

        user.validate
        expect(user.api_token).to be_present
        expect(user.api_token.length).to eq(32)
      end

      it 'does not overwrite existing api_token' do
        token = SecureRandom.base58(32)
        user = User.new(
          email: 'test@example.com',
          obsidian_vault_path: '/path',
          api_token: token
        )

        user.validate
        expect(user.api_token).to eq(token)
      end

      it 'ensures api_token is always unique' do
        user1 = create(:user)
        user2 = create(:user)

        expect(user1.api_token).not_to eq(user2.api_token)
      end
    end
  end

  describe 'token uniqueness' do
    it 'ensures unique api_token across users' do
      user1 = create(:user)
      user2 = build(:user, api_token: user1.api_token)

      expect(user2).not_to be_valid
      expect(user2.errors[:api_token]).to include('has already been taken')
    end
  end
end
