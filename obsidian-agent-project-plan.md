# Obsidian Research Agent - Project Context & Build Plan

## Project Overview

An agentic AI application built with Ruby on Rails that helps with personal knowledge management by researching topics, generating summaries, and publishing them as markdown files to Obsidian.

### Core Concept

As users browse the web or use AI tools like Claude to research topics, they can trigger this agent to:
1. Process and analyze the content
2. Generate intelligent summaries using Claude API
3. Organize and format as Obsidian-compatible markdown
4. Automatically publish to their Obsidian vault

### Architecture

- **Backend**: Ruby on Rails API-first application
- **AI Processing**: Anthropic Claude API (Sonnet 4)
- **Background Jobs**: Solid Queue for async processing
- **Storage**: MySQL 8.0+ for metadata, filesystem for Obsidian notes
- **Interfaces**: 
  - RESTful API (primary)
  - CLI tool for command-line access
  - Web dashboard (optional)
  - MCP server for Claude CLI integration (future)

## Technical Stack

### Core Dependencies
```ruby
# Essential gems
gem 'mysql2', '~> 0.5'   # MySQL adapter
gem 'solid_queue'        # Background job processing (no Redis needed!)
gem 'anthropic-rb'       # Claude API client
gem 'rack-cors'          # API CORS support
gem 'bcrypt'             # Secure token generation

# Development/Testing
gem 'rspec-rails'
gem 'factory_bot_rails'
gem 'faker'
gem 'pry-rails'
gem 'dotenv-rails'       # Environment variable management

# Testing
gem 'shoulda-matchers'   # RSpec matchers for Rails
gem 'webmock'            # Mock HTTP requests
gem 'vcr'                # Record/replay API interactions
```

### External Services
- Anthropic Claude API (for summarization and content processing)
- MySQL 8.0+ (for data persistence and job queue)

### Why Solid Queue?
- **No Redis dependency** - Uses MySQL for job storage
- **Simpler infrastructure** - One less service to manage
- **ACID guarantees** - Transactional safety with MySQL
- **Built for Rails** - Official Rails 8+ background job solution
- **Perfect for this use case** - Low-to-medium volume processing

## Database Schema

### Users Table
```ruby
create_table :users do |t|
  t.string :email, null: false
  t.string :api_token, null: false
  t.string :obsidian_vault_path
  t.timestamps
  
  t.index :email, unique: true
  t.index :api_token, unique: true
end
```

### Captures Table
```ruby
create_table :captures do |t|
  t.references :user, null: false, foreign_key: true
  t.text :content, null: false, limit: 16777215  # MEDIUMTEXT for large content
  t.string :content_type, default: 'conversation'
  t.string :context
  t.json :tags, default: []  # MySQL 8.0+ JSON support
  t.integer :status, default: 0
  
  # Processing results
  t.text :summary, limit: 16777215  # MEDIUMTEXT
  t.text :key_points
  t.json :metadata  # MySQL 8.0+ JSON support
  
  # Output
  t.text :markdown_content, limit: 16777215  # MEDIUMTEXT
  t.string :obsidian_path
  t.string :obsidian_folder
  
  t.datetime :published_at
  t.text :error_message
  
  t.timestamps
  
  t.index :status
  t.index :user_id
  t.index :created_at
end
```

### Templates Table
```ruby
create_table :templates do |t|
  t.references :user, null: false, foreign_key: true
  t.string :name, null: false
  t.text :prompt_template, null: false, limit: 16777215
  t.text :markdown_template, limit: 16777215
  t.boolean :is_default, default: false
  t.timestamps
  
  t.index [:user_id, :name], unique: true
end
```

## API Design

### Authentication
- Bearer token authentication via `Authorization` header
- Format: `Authorization: Bearer <api_token>`

### Endpoints

#### POST /api/v1/captures
Create a new capture and trigger processing.

**Request:**
```json
{
  "content": "Raw content to process...",
  "content_type": "conversation",
  "context": "What this content is about",
  "tags": ["ai", "rails"]
}
```

**Response (202 Accepted):**
```json
{
  "job_id": "123",
  "status": "processing"
}
```

#### GET /api/v1/captures/:id
Check processing status and results.

**Response:**
```json
{
  "id": "123",
  "status": "published",
  "obsidian_path": "Research/AI Agents.md",
  "created_at": "2024-12-13T10:00:00Z",
  "published_at": "2024-12-13T10:01:30Z"
}
```

#### GET /api/v1/captures
List recent captures with optional filtering.

**Query params:**
- `status`: Filter by status (pending, processing, published, failed)
- `limit`: Number of results (default: 50)

## Processing Pipeline

### Job Flow (CaptureProcessorJob)

1. **Extract Content** (ExtractContentService)
   - Clean HTML if webpage
   - Extract text from PDF if needed
   - Normalize whitespace and formatting

2. **Generate Summary** (GenerateSummaryService)
   - Load appropriate template
   - Call Claude API with content
   - Parse response into structured data
   - Extract title, key points, suggested tags

3. **Enrich Metadata** (EnrichMetadataService)
   - Find related notes in vault
   - Merge user tags with AI-suggested tags
   - Determine appropriate folder

4. **Format Markdown** (FormatMarkdownService)
   - Apply markdown template
   - Add YAML frontmatter
   - Format tags and links
   - Include related notes section

5. **Publish to Vault** (PublishToVaultService)
   - Generate unique filename
   - Create folder structure if needed
   - Write markdown file to vault
   - Update capture with file path

### Status Flow
```
pending → processing → summarizing → enriching → formatting → published
                                                              ↓
                                                           failed
```

## Default Templates

### Standard Template
```markdown
---
created: {{created_at}}
tags: {{tags}}
type: {{content_type}}
---

# {{title}}

{{context_section}}

## Summary

{{summary}}

## Key Points

{{key_points}}

{{related_notes_section}}
```

### Conversation Template
```markdown
# Conversation: {{context}}

{{summary}}

## Main Takeaways

{{key_points}}
```

### Article Template
```markdown
# {{title}}

Source: {{source_url}}

{{summary}}

## Key Arguments

{{key_points}}
```

## CLI Tool Design

### Installation
```bash
chmod +x bin/obsidian-capture
ln -s "$(pwd)/bin/obsidian-capture" /usr/local/bin/obsidian-capture
```

### Usage Examples
```bash
# Basic capture from stdin
echo "Content here" | obsidian-capture --context "Testing"

# Capture with tags
cat notes.md | obsidian-capture --tags "ai,research"

# Capture and wait for completion
pbpaste | obsidian-capture --wait

# Capture from file
obsidian-capture research.txt --type article

# Integration with Claude CLI
claude-cli chat "Summarize X" | obsidian-capture --context "Research"
```

### Environment Variables
```bash
export OBSIDIAN_API_TOKEN="your-token-here"
export OBSIDIAN_API_BASE="http://localhost:3000"
```

## Build Plan - 14 Day Schedule

### Phase 1: Core API (Days 1-5)

#### Day 1: Project Setup
- [ ] Create Rails app: `rails new obsidian-agent --api --database=mysql`
- [ ] Add required gems to Gemfile
- [ ] Run `bundle install`
- [ ] Configure database in `config/database.yml`
- [ ] Create database: `rails db:create`
- [ ] Install Solid Queue: `bin/rails solid_queue:install`
- [ ] Set up environment variables (.env file)

**Deliverable:** Working Rails app skeleton

**Notes:**
- Solid Queue creates `db/queue_schema.rb` and `config/queue.yml`
- No Redis configuration needed!
- Test job processing with `bin/jobs`

#### Day 2: Database Schema & Models
- [ ] Create migration for users table
- [ ] Create migration for captures table
- [ ] Create migration for templates table
- [ ] Run migrations: `rails db:migrate`
- [ ] Create User model with validations
- [ ] Create Capture model with status enum
- [ ] Create Template model with defaults
- [ ] Add model associations
- [ ] Add indexes for performance

**Deliverable:** Database schema and ActiveRecord models

**MySQL-specific notes:**
- Use `t.json` for tags and metadata (MySQL 8.0+)
- Use `limit: 16777215` for MEDIUMTEXT columns
- Ensure proper character encoding (utf8mb4)

#### Day 3: API Controllers & Authentication
- [ ] Create ApiController base class
- [ ] Implement token authentication
- [ ] Create Api::V1::CapturesController
  - [ ] #index - list captures
  - [ ] #show - get capture details
  - [ ] #create - create new capture
- [ ] Create Api::V1::TemplatesController
  - [ ] #index, #create, #update
- [ ] Create CaptureSerializer
- [ ] Add routes for API endpoints

**Deliverable:** Functional API endpoints with authentication

#### Day 4: Background Processing Services
- [ ] Configure Solid Queue
- [ ] Create CaptureProcessorJob
- [ ] Implement ExtractContentService
- [ ] Implement GenerateSummaryService
  - [ ] Integrate Anthropic Claude API
  - [ ] Template rendering
  - [ ] Response parsing
- [ ] Implement EnrichMetadataService
- [ ] Implement FormatMarkdownService
- [ ] Implement PublishToVaultService
- [ ] Add error handling and logging

**Deliverable:** Complete processing pipeline

**Notes:**
- Jobs are stored in MySQL via Solid Queue
- Test with: `CaptureProcessorJob.perform_later(capture_id)`
- Monitor jobs in MySQL: `SELECT * FROM solid_queue_jobs`

#### Day 5: Testing & Configuration
- [ ] Set up RSpec
- [ ] Write request specs for API
- [ ] Write service specs
- [ ] Add factory_bot factories
- [ ] Create seed data
- [ ] Document environment variables
- [ ] Test end-to-end workflow
- [ ] Add VCR cassettes for Claude API

**Deliverable:** Tested, working API

**Milestone 1 Success Criteria:**
- ✅ Can create captures via API
- ✅ Background processing completes successfully
- ✅ Files written to Obsidian vault correctly
- ✅ All tests passing
- ✅ Solid Queue processing jobs reliably

### Phase 2: CLI Tool (Days 6-7)

#### Day 6: Build CLI Script
- [ ] Create bin/obsidian-capture script
- [ ] Implement argument parsing (OptionParser)
- [ ] Implement stdin reading
- [ ] Implement API client
  - [ ] POST to /captures endpoint
  - [ ] GET for status checking
- [ ] Add --wait flag for sync mode
- [ ] Add --tags, --context, --type flags
- [ ] Implement colorized output
- [ ] Add error handling

**Deliverable:** Working CLI tool

#### Day 7: Integration Testing & Documentation
- [ ] Test basic capture workflow
- [ ] Test with different content types
- [ ] Test --wait flag
- [ ] Create shell aliases examples
- [ ] Write CLI documentation
- [ ] Create usage examples
- [ ] Document Claude CLI integration

**Deliverable:** Documented, tested CLI

**Milestone 2 Success Criteria:**
- ✅ Can capture from command line
- ✅ Integration with Claude CLI works
- ✅ Status checking functional
- ✅ Documentation complete

### Phase 3: Optional Web Dashboard (Days 8-10)

#### Day 8: Basic Dashboard UI
- [ ] Add view gems (importmap, turbo, stimulus, tailwindcss)
- [ ] Create DashboardController
- [ ] Build index view with:
  - [ ] Statistics cards
  - [ ] Recent captures table
  - [ ] Status indicators
- [ ] Add basic authentication
- [ ] Style with Tailwind CSS

**Deliverable:** Basic dashboard view

#### Day 9: Template Management UI
- [ ] Create TemplatesController
- [ ] Build template CRUD views:
  - [ ] List templates
  - [ ] New/Edit template form
  - [ ] Template preview
- [ ] Add template testing interface
- [ ] Implement default template toggle

**Deliverable:** Template management interface

#### Day 10: Settings & Configuration
- [ ] Create SettingsController
- [ ] Build settings form:
  - [ ] Obsidian vault path
  - [ ] API token management
  - [ ] Processing preferences
  - [ ] Folder mapping rules
- [ ] Add form validations
- [ ] Implement settings update

**Deliverable:** Settings interface

**Milestone 3 Success Criteria:**
- ✅ Can view captures in browser
- ✅ Template management works
- ✅ Settings configurable
- ✅ UI polished and functional

### Phase 4: MCP Server (Days 11-14)

#### Day 11-12: MCP Server Implementation
- [ ] Create mcp_server directory
- [ ] Build Sinatra-based MCP server
- [ ] Implement MCP protocol endpoints:
  - [ ] GET /sse - Server-sent events
  - [ ] POST /message - Handle tool calls
- [ ] Implement tools:
  - [ ] save_to_obsidian tool
  - [ ] check_obsidian_status tool
- [ ] Add tool schemas
- [ ] Integrate with Rails API

**Deliverable:** Working MCP server

#### Day 13: MCP Testing
- [ ] Configure Claude CLI MCP settings
- [ ] Test tool discovery
- [ ] Test save_to_obsidian tool
- [ ] Test status checking
- [ ] Test error handling
- [ ] Verify end-to-end workflow

**Deliverable:** Tested MCP integration

#### Day 14: Documentation & Polish
- [ ] Write MCP setup guide
- [ ] Document Claude CLI configuration
- [ ] Create usage examples
- [ ] Add troubleshooting section
- [ ] Record demo video
- [ ] Final testing and bug fixes

**Deliverable:** Complete documentation

**Milestone 4 Success Criteria:**
- ✅ MCP server runs stably
- ✅ Claude can discover and use tools
- ✅ End-to-end workflow complete
- ✅ Documentation comprehensive

## Service Implementation Details

### GenerateSummaryService
```ruby
class GenerateSummaryService
  def self.call(capture)
    new(capture).call
  end
  
  def initialize(capture)
    @capture = capture
    @client = Anthropic::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
  end
  
  def call
    template = get_template
    prompt = render_prompt(template)
    
    response = @client.messages(
      parameters: {
        model: 'claude-sonnet-4-20250514',
        max_tokens: 4000,
        messages: [
          { role: 'user', content: prompt }
        ]
      }
    )
    
    content = response.dig('content', 0, 'text')
    parsed = parse_response(content)
    
    @capture.update(
      summary: parsed[:summary],
      key_points: parsed[:key_points],
      metadata: @capture.metadata.merge(
        title: parsed[:title],
        generated_tags: parsed[:suggested_tags]
      )
    )
  end
  
  private
  
  def get_template
    # Load user's template or default
    @capture.user.templates.find_by(
      name: @capture.content_type,
      is_default: true
    ) || default_template
  end
  
  def default_template
    Template::DEFAULTS[@capture.content_type] || Template::DEFAULTS['standard']
  end
  
  def render_prompt(template)
    template[:prompt]
      .gsub('{{content}}', @capture.content)
      .gsub('{{context}}', @capture.context || 'General research')
  end
  
  def parse_response(content)
    # Parse Claude's response into structured data
    {
      summary: content,
      key_points: extract_key_points(content),
      title: extract_title(content),
      suggested_tags: extract_tags(content)
    }
  end
  
  def extract_key_points(content)
    # Extract bullet points or numbered lists
    content.scan(/^[-*•]\s+(.+)$/).flatten.join("\n")
  end
  
  def extract_title(content)
    # Extract first heading or generate from context
    content.match(/^#\s+(.+)$/)&.[](1) || 
      @capture.context || 
      "Research #{@capture.created_at.strftime('%Y-%m-%d')}"
  end
  
  def extract_tags(content)
    # Simple tag extraction - could use NLP
    []
  end
end
```

### PublishToVaultService
```ruby
class PublishToVaultService
  def self.call(capture)
    new(capture).call
  end
  
  def initialize(capture)
    @capture = capture
  end
  
  def call
    vault_path = @capture.user.obsidian_vault_path
    raise "No Obsidian vault path configured" unless vault_path
    
    filename = generate_filename
    folder_path = File.join(vault_path, @capture.obsidian_folder)
    file_path = File.join(folder_path, filename)
    
    FileUtils.mkdir_p(folder_path)
    File.write(file_path, @capture.markdown_content)
    
    @capture.update(
      obsidian_path: File.join(@capture.obsidian_folder, filename)
    )
  end
  
  private
  
  def generate_filename
    title = @capture.metadata['title'] || 'Untitled'
    slug = title.downcase
                .gsub(/[^a-z0-9\s-]/, '')
                .gsub(/\s+/, '-')
                .slice(0, 50)
    
    "#{slug}-#{@capture.id}.md"
  end
end
```

## Testing Strategy

### Unit Tests
- Model validations
- Service logic
- Template rendering
- Filename generation
- JSON column handling (MySQL-specific)

### Integration Tests
- API endpoints
- Authentication
- Background job processing with Solid Queue
- File system operations

### End-to-End Tests
- Complete capture workflow
- CLI tool integration
- Error handling
- Status transitions
- Job retries and failures

### RSpec Setup
```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  # Use transactional fixtures
  config.use_transactional_fixtures = true
  
  # Factory Bot
  config.include FactoryBot::Syntax::Methods
  
  # Shoulda Matchers
  config.include(Shoulda::Matchers::ActiveModel, type: :model)
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)
  
  # VCR for API testing
  VCR.configure do |c|
    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    c.hook_into :webmock
    c.filter_sensitive_data('<ANTHROPIC_API_KEY>') { ENV['ANTHROPIC_API_KEY'] }
  end
end
```

## Configuration Files

### config/database.yml
```yaml
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: <%= ENV.fetch("MYSQL_PASSWORD") { "" } %>
  host: localhost

development:
  <<: *default
  database: obsidian_agent_development

test:
  <<: *default
  database: obsidian_agent_test

production:
  <<: *default
  database: obsidian_agent_production
  username: <%= ENV['DATABASE_USERNAME'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  host: <%= ENV['DATABASE_HOST'] %>
```

### config/routes.rb
```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :captures, only: [:index, :show, :create]
      resources :templates, only: [:index, :create, :update, :destroy]
    end
  end
  
  # Optional dashboard routes
  root 'dashboard#index'
  resources :dashboard, only: [:index]
  resources :templates
  resource :settings, only: [:show, :update]
end
```

### config/queue.yml (Solid Queue)
```yaml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: 2
      polling_interval: 0.1

development:
  dispatchers:
    - polling_interval: 1
      batch_size: 100
  workers:
    - queues: "*"
      threads: 3
      processes: 1
      polling_interval: 1
```

### .env.example
```bash
# Anthropic API
ANTHROPIC_API_KEY=your_anthropic_api_key

# MySQL Database
MYSQL_PASSWORD=your_mysql_password
DATABASE_USERNAME=root
DATABASE_PASSWORD=your_production_password
DATABASE_HOST=localhost

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=generate_with_rails_secret

# Obsidian (for development)
OBSIDIAN_VAULT_PATH=/path/to/your/vault
```

## Running the Application

### Development
```bash
# Terminal 1 - Rails server
rails s

# Terminal 2 - Solid Queue job processor
bin/jobs

# Or use Foreman/Overmind with Procfile:
# Procfile.dev
web: bundle exec rails server
worker: bundle exec rake solid_queue:start
```

### Production
```bash
# Using systemd or similar process manager
# web: bundle exec rails server -e production
# worker: bundle exec rake solid_queue:start
```

## Deployment Considerations

### Production Setup
- Use environment variables for all secrets
- Configure MySQL for production workload
- Set up database backups (MySQL dumps)
- Monitor Solid Queue job processing
- Log rotation for Rails logs
- Consider connection pooling for MySQL

### MySQL Performance Tuning
```sql
-- Recommended MySQL settings for Solid Queue
[mysqld]
innodb_lock_wait_timeout = 50
max_connections = 200
innodb_buffer_pool_size = 256M  # Adjust based on RAM
innodb_log_file_size = 64M
```

### Security
- API tokens stored hashed in database
- HTTPS only in production
- Rate limiting on API endpoints
- Input validation and sanitization
- CORS configuration
- MySQL user permissions (least privilege)

## Future Enhancements

### Phase 5+
- [ ] Semantic search across vault
- [ ] Auto-linking related notes
- [ ] Multi-user support
- [ ] OAuth integration
- [ ] Browser extension
- [ ] Mobile app
- [ ] Real-time collaboration
- [ ] Version history for notes
- [ ] Export to other formats
- [ ] Integration with other PKM tools
- [ ] Batch processing of multiple captures
- [ ] Webhook notifications

## Success Metrics

- Time to process capture: < 30 seconds
- API response time: < 200ms
- Test coverage: > 80%
- Zero data loss
- Markdown compatibility: 100%
- Job processing reliability: > 99%

## References & Resources

- [Anthropic API Documentation](https://docs.anthropic.com/)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [Obsidian Markdown Format](https://help.obsidian.md/Editing+and+formatting/Basic+formatting+syntax)
- [Rails API-only Guide](https://guides.rubyonrails.org/api_app.html)
- [Solid Queue Documentation](https://github.com/basecamp/solid_queue)
- [MySQL 8.0 Documentation](https://dev.mysql.com/doc/refman/8.0/en/)
- [RSpec Rails Documentation](https://github.com/rspec/rspec-rails)

## Development Workflow

1. Create feature branch
2. Write tests first (TDD with RSpec)
3. Implement feature
4. Ensure tests pass
5. Manual testing
6. Code review
7. Merge to main
8. Deploy

## Getting Started Checklist

- [ ] Install MySQL 8.0+
- [ ] Create Rails application with MySQL
- [ ] Set up development environment
- [ ] Configure database credentials
- [ ] Install dependencies (`bundle install`)
- [ ] Create .env file with credentials
- [ ] Run migrations (`rails db:migrate`)
- [ ] Install Solid Queue (`bin/rails solid_queue:install`)
- [ ] Start job processor (`bin/jobs`)
- [ ] Start Rails server (`rails s`)
- [ ] Run test suite (`rspec`)
- [ ] Begin Day 1 tasks

## MySQL-Specific Notes

### JSON Column Usage
```ruby
# Working with JSON columns in MySQL
capture = Capture.create(
  tags: ['ai', 'rails'],           # Stored as JSON array
  metadata: { title: 'Test' }      # Stored as JSON object
)

# Querying JSON columns
Capture.where("JSON_CONTAINS(tags, ?)", '"ai"'.to_json)
Capture.where("JSON_EXTRACT(metadata, '$.title') = ?", 'Test')
```

### Character Encoding

Ensure utf8mb4 encoding for full Unicode support (including emojis):
```ruby
# In migrations
create_table :captures, charset: 'utf8mb4', collation: 'utf8mb4_unicode_ci' do |t|
  # ...
end
```

### Text Field Limits

MySQL text field sizes:
- `TEXT`: 65,535 bytes
- `MEDIUMTEXT`: 16,777,215 bytes (use for large content)
- `LONGTEXT`: 4,294,967,295 bytes

## Questions to Address During Development

1. How should we handle failed API calls to Claude?
   - Retry with exponential backoff via Solid Queue
2. Should we cache Claude responses?
   - Yes, consider caching in captures table
3. How to handle very large content (>100k chars)?
   - Use MEDIUMTEXT, chunk if needed
4. Should we support batch processing?
   - Phase 5 enhancement
5. How to handle Obsidian vault sync conflicts?
   - Generate unique filenames with ID
6. Should we version the markdown files?
   - Store versions in metadata JSON
7. How to handle template versioning?
   - Add version column to templates table
8. Should we support webhooks for notifications?
   - Phase 5 enhancement

## Notes

- This is an API-first design - CLI and web UI are secondary
- Processing is async by default for better UX via Solid Queue
- Obsidian vault path can be local or network mount
- Templates are user-customizable for flexibility
- MCP server is optional but highly valuable
- Focus on simplicity and reliability over features
- **MySQL 8.0+ required** for JSON support
- **No Redis needed** - Solid Queue uses MySQL for everything
- Test coverage with RSpec for confidence

---

**Project Start Date:** TBD
**Expected Completion:** 2-3 weeks
**Estimated Hours:** 50-60 hours
**Current Phase:** Planning
**Next Action:** Day 1 - Project Setup with MySQL and Solid Queue
**Tech Stack:** Rails 7.1+ | MySQL 8.0+ | Solid Queue | RSpec | Anthropic Claude API