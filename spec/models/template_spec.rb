require 'rails_helper'

RSpec.describe Template, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:template) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:prompt_template) }

    it 'validates uniqueness of name scoped to user' do
      user = create(:user)
      create(:template, user: user, name: 'test-template')

      duplicate = build(:template, user: user, name: 'test-template')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end

    it 'allows same name for different users' do
      user1 = create(:user)
      user2 = create(:user)

      create(:template, user: user1, name: 'shared-name')
      duplicate = build(:template, user: user2, name: 'shared-name')

      expect(duplicate).to be_valid
    end
  end

  describe '.defaults' do
    it 'returns a hash of default templates' do
      defaults = Template.defaults

      expect(defaults).to be_a(Hash)
      expect(defaults.keys).to include('standard', 'conversation')
    end

    it 'includes required template data' do
      standard = Template.defaults['standard']

      expect(standard).to have_key(:name)
      expect(standard).to have_key(:prompt_template)
      expect(standard).to have_key(:markdown_template)
      expect(standard[:prompt_template]).to include('{{content}}')
      expect(standard[:markdown_template]).to include('{{title}}')
    end

    it 'has conversation template' do
      conversation = Template.defaults['conversation']

      expect(conversation[:name]).to eq('conversation')
      expect(conversation[:prompt_template]).to include('conversation')
      expect(conversation[:markdown_template]).to include('Conversation')
    end
  end

  describe 'creating from defaults' do
    let(:user) { create(:user) }

    it 'can create templates from defaults' do
      Template.defaults.each do |type, data|
        template = user.templates.create!(
          name: data[:name],
          prompt_template: data[:prompt_template],
          markdown_template: data[:markdown_template],
          is_default: true
        )

        expect(template).to be_persisted
        expect(template.is_default).to be true
      end
    end
  end
end
