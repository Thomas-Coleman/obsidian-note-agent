FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    obsidian_vault_path { "/Users/tomcoleman/Documents/Obsidian/Tom's Obsidian Notes" }

    # api_token is auto-generated in before_validation callback

    trait :with_custom_vault do
      obsidian_vault_path { "/custom/vault/path" }
    end
  end
end
