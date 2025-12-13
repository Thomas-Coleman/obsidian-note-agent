FactoryBot.define do
  factory :capture do
    user
    content { Faker::Lorem.paragraph(sentence_count: 10) }
    content_type { 'conversation' }
    context { Faker::Lorem.sentence }
    tags { ['test', 'rspec'] }
    
    trait :pending do
      status { :pending }
    end
    
    trait :processing do
      status { :processing }
    end
    
    trait :published do
      status { :published }
      summary { Faker::Lorem.paragraph(sentence_count: 3) }
      key_points { Faker::Lorem.paragraphs(number: 3).join("\n") }
      markdown_content { "# Test Note\n\n#{Faker::Lorem.paragraph}" }
      obsidian_path { "Captures/test-note-#{SecureRandom.hex(4)}.md" }
      published_at { Time.current }
    end
    
    trait :failed do
      status { :failed }
      error_message { "Processing failed: #{Faker::Lorem.sentence}" }
    end
    
    trait :article do
      content_type { 'article' }
    end
  end
end