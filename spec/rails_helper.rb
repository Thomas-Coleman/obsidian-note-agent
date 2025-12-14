require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Explicitly require api_helpers FIRST
require_relative 'support/api_helpers'

# Debug
puts "ApiHelpers is a: #{ApiHelpers.class}"
puts "ApiHelpers methods: #{ApiHelpers.instance_methods(false)}"

# Add additional requires below this line. Rails is not loaded until this point!

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true

  # Factory Bot configuration
  config.include FactoryBot::Syntax::Methods
  
  # Include API helpers for request specs
  config.include ApiHelpers, type: :request

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
end

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end