# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


# Create a test user
user = User.find_or_initialize_by(email: 'colemant72@gmail.com')
if user.new_record?
  user.obsidian_vault_path = "/Users/tomcoleman/Documents/Obsidian/Tom's Obsidian Notes"
  user.save!
  puts "Created user: #{user.email}"
else
  puts "User already exists: #{user.email}"
end

puts "API Token: #{user.api_token}"
puts "Save this token for API requests!"

# Create or update default templates
Template.defaults.each do |type, template_data|
  template = user.templates.find_or_initialize_by(name: template_data[:name])
  template.prompt_template = template_data[:prompt_template]
  template.markdown_template = template_data[:markdown_template]
  template.save!

  action = template.previously_new_record? ? "Created" : "Updated"
  puts "#{action} template: #{template.name}"
end

puts "\n✅ Seed data created successfully!"
