# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Obsidian Note Agent is a Rails 8 API application that processes text captures (conversations, notes, etc.) using Claude AI and writes formatted Markdown files to an Obsidian vault. The app accepts raw content via API, processes it through Claude to extract titles/summaries/tags, and outputs structured Markdown notes.

## Common Commands

### Development
```bash
bin/setup              # Initial setup
bin/dev                # Start development server
bin/rails console      # Rails console
bin/rails db:migrate   # Run migrations
bin/rails db:seed      # Seed database
```

### Testing
```bash
bin/rails test                    # Run all tests
bin/rails test test/models/       # Run model tests
bin/rails test:system              # Run system tests
bundle exec rspec                  # Run RSpec tests
bundle exec rspec spec/models/     # Run specific RSpec tests
```

### Code Quality
```bash
bin/rubocop                        # Run linter
bin/rubocop -a                     # Auto-fix linting issues
bin/brakeman                       # Security scan
bin/bundler-audit                  # Gem vulnerability scan
bin/ci                             # Run full CI suite locally
```

## Architecture

### Processing Pipeline

The core functionality follows a multi-stage pipeline orchestrated by `ProcessCaptureJob`:

1. **API Request** → `CapturesController#create` receives raw content
2. **Job Enqueue** → `ProcessCaptureJob` is queued for background processing
3. **Processing** → `CaptureProcessor` orchestrates the pipeline:
   - Finds appropriate template (user-specific or default)
   - Sends content to Claude via `ClaudeService`
   - Parses AI response to extract structured data (title, summary, tags, key points)
   - Renders markdown using template variables
   - Writes file to Obsidian vault via `ObsidianWriter`
4. **Status Updates** → Capture model tracks status: `pending` → `processing` → `published`/`failed`

### Key Services

**CaptureProcessor** (`app/services/capture_processor.rb`)
- Central orchestration service for the processing pipeline
- Handles template selection, Claude API interaction, response parsing, markdown rendering
- Uses simple text parsing to extract structured data from Claude's response
- Template variables: `{{content}}`, `{{context}}`, `{{title}}`, `{{summary}}`, `{{tags}}`, etc.

**ClaudeService** (`app/services/claude_service.rb`)
- Wrapper around `ruby-anthropic` gem
- Currently uses `claude-sonnet-4-20250514` model
- Requires `ANTHROPIC_API_KEY` environment variable

**ObsidianWriter** (`app/services/obsidian_writer.rb`)
- Writes formatted markdown to user's Obsidian vault
- Handles filename sanitization and collision avoidance
- Uses `User.obsidian_vault_path` for target directory

### Data Models

**Capture** - The main entity representing content to be processed
- Status enum: `pending`, `processing`, `summarizing`, `enriching`, `formatting`, `published`, `failed`
- Stores both raw input (`content`, `context`, `content_type`) and generated output (`generated_title`, `generated_summary`, etc.)
- Supports JSON fields for `tags` and `metadata`

**Template** - Defines how content is processed and formatted
- Two template types: `prompt_template` (sent to Claude) and `markdown_template` (final output format)
- Includes default templates: `"standard"` and `"conversation"`
- Users can create custom templates with their own variables and formatting

**User** - Authenticated API user
- Uses simple token-based authentication (`api_token` in Bearer header)
- Stores `obsidian_vault_path` for file writing

### API Structure

RESTful JSON API at `/api/v1/`
- Authentication via `ApiAuthenticable` concern (Bearer token)
- Base controller provides `render_success` helper for consistent responses
- Pagination via Kaminari (20 items per page default)
- Controllers: `CapturesController`, `TemplatesController`

### Background Jobs

Uses Solid Queue (Rails 8 default) for background job processing:
- `ProcessCaptureJob` - Main processing pipeline with exponential backoff retry (3 attempts)
- Updates capture status and stores results or error messages

## Configuration

### Environment Variables
- `ANTHROPIC_API_KEY` - Required for Claude API access
- `DATABASE_URL` - MySQL connection (defaults configured for development/test)
- `RAILS_MASTER_KEY` - Rails credentials (not in version control)

### Database
- MySQL 8 with `utf8mb4` charset for full Unicode support
- Uses Solid Cache, Solid Queue, and Solid Cable (Rails 8 defaults)
- Large text fields use MEDIUMTEXT for captures content/summaries

## Testing

- RSpec for all new tests (configured with FactoryBot, Faker, Shoulda Matchers)
- Model specs in `spec/models/`
- Request specs in `spec/requests/api/v1/`
- Use factories instead of fixtures

## Deployment

- Configured for Kamal deployment
- CI/CD via GitHub Actions (`.github/workflows/ci.yml`)
- Security scanning: Brakeman, Bundler Audit, Importmap Audit
- Linting: RuboCop Rails Omakase style guide
