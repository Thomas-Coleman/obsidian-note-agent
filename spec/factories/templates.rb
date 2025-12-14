FactoryBot.define do
  factory :template do
    user
    sequence(:name) { |n| "template_#{n}" }
    prompt_template { "Analyze: {{content}}" }
    markdown_template { "# {{title}}\n\n{{summary}}" }
    is_default { false }

    trait :default do
      is_default { true }
    end

    trait :standard do
      name { 'standard' }
      prompt_template { Template.defaults['standard'][:prompt_template] }
      markdown_template { Template.defaults['standard'][:markdown_template] }
    end

    trait :conversation do
      name { 'conversation' }
      prompt_template { Template.defaults['conversation'][:prompt_template] }
      markdown_template { Template.defaults['conversation'][:markdown_template] }
    end
  end
end
