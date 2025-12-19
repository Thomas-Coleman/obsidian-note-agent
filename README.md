# Obsidian Note Agent

An intelligent note capture system that processes text content through Claude AI and outputs structured Markdown files to your Obsidian vault.

## Monorepo Structure

This project is organized as a monorepo containing multiple related components:

```
obsidian-note-agent/
├── note-agent-app/          # Rails API application
│   ├── app/                 # Rails application code
│   ├── config/              # Rails configuration
│   ├── db/                  # Database migrations and schema
│   ├── spec/                # RSpec tests
│   └── README.md            # Rails app documentation
│
├── chrome-extension/        # Chrome extension for web capture
│   ├── manifest.json        # Extension configuration
│   ├── popup/               # Extension UI
│   ├── content/             # Content scripts
│   ├── background/          # Service worker
│   └── lib/                 # Third-party libraries
│
├── docker-compose.yml       # Production environment orchestration
├── .env.production          # Production environment variables
├── bin/production           # Production management script
└── PRODUCTION_SETUP.md      # Production setup guide
```

## Components

### Rails API (`note-agent-app/`)

A Rails 8 API application that:
- Accepts text captures via RESTful API
- Processes content through Claude AI to extract titles, summaries, and tags
- Generates formatted Markdown files
- Writes files directly to your Obsidian vault

**[View Rails App Documentation →](note-agent-app/README.md)**

### Chrome Extension (`chrome-extension/`)

A Chrome extension (in development) that:
- Captures web content using Mozilla Readability
- Extracts rich metadata (URL, author, publish date)
- Auto-detects content type
- Sends captured content to the Rails API

**Status:** In development

## Quick Start

### Local Production Setup

Run the Rails API in production mode using Docker Compose:

```bash
# 1. Configure environment
cp .env.production.example .env.production
# Edit .env.production with your API keys and vault path

# 2. Start services
bin/production start

# 3. Create a user
docker exec obsidian_note_agent_app bin/rails runner "
user = User.create!(email: 'you@example.com')
puts 'API Token: ' + user.api_token
"

# 4. Test API
curl -X POST http://localhost/api/v1/captures \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"capture": {"content": "Test note", "content_type": "note"}}'
```

**[View Production Setup Guide →](PRODUCTION_SETUP.md)**

### Development Setup

For Rails app development:

```bash
cd note-agent-app
bin/setup
bin/dev
```

See the [Rails app README](note-agent-app/README.md) for detailed development instructions.

## Key Features

- **AI-Powered Processing**: Uses Claude AI to extract titles, summaries, and tags
- **Flexible Templates**: Customize how content is processed and formatted
- **Direct Vault Integration**: Writes markdown files directly to your Obsidian vault
- **RESTful API**: Simple JSON API for creating captures
- **Background Processing**: Asynchronous job processing with Solid Queue
- **Rich Metadata**: Support for tags, context, and custom metadata
- **Multiple Content Types**: Handles conversations, articles, notes, and reference material

## Requirements

- **For Production**: Docker Desktop, Obsidian, Anthropic API key
- **For Development**: Ruby 3.4+, MySQL 8, Node.js, Obsidian, Anthropic API key

## Documentation

- [Production Setup Guide](PRODUCTION_SETUP.md) - Docker Compose deployment
- [Rails App README](note-agent-app/README.md) - Application architecture and development
- [Rails App CLAUDE.md](note-agent-app/CLAUDE.md) - Guidance for Claude Code
- [Original Project Plan](obsidian-agent-project-plan.md) - Initial project design

## Architecture Overview

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│  Chrome Ext     │────▶│  Rails API   │────▶│  Claude AI  │
│  (captures web) │     │  (processes) │     │             │
└─────────────────┘     └──────┬───────┘     └─────────────┘
                               │
                               ▼
                        ┌──────────────┐
                        │   Obsidian   │
                        │     Vault    │
                        │  (.md files) │
                        └──────────────┘
```

## API Endpoints

### Captures
- `GET /api/v1/captures` - List all captures
- `POST /api/v1/captures` - Create new capture
- `GET /api/v1/captures/:id` - Get capture details
- `PATCH /api/v1/captures/:id` - Update capture
- `DELETE /api/v1/captures/:id` - Delete capture

### Templates
- `GET /api/v1/templates` - List all templates
- `POST /api/v1/templates` - Create custom template
- `GET /api/v1/templates/:id` - Get template details
- `PATCH /api/v1/templates/:id` - Update template
- `DELETE /api/v1/templates/:id` - Delete template

## Authentication

API uses Bearer token authentication:

```bash
Authorization: Bearer YOUR_API_TOKEN
```

Get your API token by creating a user in the Rails console.

## License

[Add your license here]

## Contributing

[Add contributing guidelines here]

## Support

For issues:
1. Check the troubleshooting section in [PRODUCTION_SETUP.md](PRODUCTION_SETUP.md)
2. Review [Rails app documentation](note-agent-app/README.md)
3. Check application logs: `bin/production logs`
