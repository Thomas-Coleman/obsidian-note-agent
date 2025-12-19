# Obsidian Note Agent - Chrome Extension

A Chrome extension that captures web content using Mozilla's Readability library, enriches it with metadata, and sends it to the Obsidian Note Agent Rails API.

## Features

- **Smart Content Extraction**: Uses Mozilla Readability for article extraction, with fallback to selection or body text
- **Rich Metadata**: Automatically extracts URL, author, publish date, description, and more
- **Auto Content-Type Detection**: Intelligently suggests article, conversation, note, or reference based on page characteristics
- **Preview & Metadata View**: Collapsible preview of extracted content and metadata
- **Persistent Settings**: API endpoint and token stored securely in Chrome storage
- **Batch Capture**: Popup stays open after successful capture for multiple saves

## Installation

### 1. Ensure Rails API is Running

Make sure your Rails API is running in production mode:

```bash
bin/production start
# Check status
bin/production status
```

The API should be accessible at `http://localhost/api/v1`

### 2. Add Extension Icons (Required)

The extension needs PNG icons to display properly. See `assets/icons/README.md` for instructions on creating icons.

Quick option: Use an online tool like [favicon.io](https://favicon.io/favicon-generator/) to create:
- `assets/icons/icon16.png` (16x16)
- `assets/icons/icon48.png` (48x48)
- `assets/icons/icon128.png` (128x128)

### 3. Load Extension in Chrome

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable "Developer mode" (toggle in top right)
3. Click "Load unpacked"
4. Select the `chrome-extension` directory from this repository
5. The extension should now appear in your extensions list

### 4. Get Your API Token

You need to create a user account in the Rails app to get an API token.

**Quick Method (Recommended):**

```bash
docker exec obsidian_note_agent_app bin/rails runner "
user = User.create!(email: 'your@email.com')
puts '================================'
puts 'User created successfully!'
puts '================================'
puts 'Email: ' + user.email
puts 'API Token: ' + user.api_token
puts 'Obsidian Vault Path: ' + user.obsidian_vault_path
puts '================================'
puts 'SAVE THIS API TOKEN!'
puts '================================'
"
```

**Alternative (Using Rails Console):**

```bash
# Open the production console
bin/production console

# Then in the console:
user = User.create!(email: "your@email.com")
puts user.api_token
# Save this token!
```

**List All Users:**

```bash
bin/production console
# Then:
User.all.each { |u| puts "#{u.email}: #{u.api_token}" }
```

### 5. Configure Extension Settings

1. Click the extension icon in your toolbar
2. Click the gear icon to open settings
3. Enter:
   - **API Endpoint**: `http://localhost/api/v1`
   - **API Token**: The token from the step above
4. Click "Save Settings"

## Usage

### Capturing Web Content

1. Navigate to any web page you want to capture
2. Click the extension icon in your toolbar
3. The extension will automatically extract content and metadata
4. Review and adjust:
   - Content Type (auto-detected, but you can change)
   - Context (optional additional notes)
   - Tags (comma-separated)
   - Obsidian Folder (default: Captures)
5. Click "Save to Obsidian"
6. Success message appears and the popup stays open for more captures

### Content Extraction Priority

The extension uses a smart priority system:
1. **Text Selection**: If you've selected text on the page, that will be captured
2. **Readability**: For articles, uses Mozilla Readability for clean extraction
3. **Body Text**: Fallback to full page body text

### Auto Content-Type Detection

The extension intelligently detects content type:
- **Conversation**: Messaging platforms (Slack, Discord, WhatsApp, etc.)
- **Article**: Has publish date/author, extracted via Readability, >300 words
- **Note**: Short content (<300 words) without publication metadata
- **Reference**: Default fallback

### Viewing Metadata

Click "Show Metadata & Preview" to see:
- URL and domain
- Page title
- Extraction method used
- Word count
- Content preview (first 500 characters)

## Architecture

```
┌─────────────────────────────────────┐
│           Chrome Tab                 │
│  ┌─────────────────────────────┐   │
│  │   content-script.js          │   │
│  │   - Extracts content          │   │
│  │   - Uses Readability          │   │
│  │   - Parses metadata           │   │
│  └──────────┬──────────────────┘   │
└─────────────┼──────────────────────┘
              │ Message
              ▼
┌─────────────────────────────────────┐
│        Extension Popup               │
│  ┌─────────────────────────────┐   │
│  │   popup.js                    │   │
│  │   - Orchestration logic       │   │
│  │   - UI state management       │   │
│  └──────────┬──────────────────┘   │
└─────────────┼──────────────────────┘
              │ Message
              ▼
┌─────────────────────────────────────┐
│      Service Worker                  │
│  ┌─────────────────────────────┐   │
│  │   service-worker.js          │   │
│  │   - API communication         │   │
│  │   - HTTP requests             │   │
│  └──────────┬──────────────────┘   │
└─────────────┼──────────────────────┘
              │ HTTP POST
              ▼
┌─────────────────────────────────────┐
│      Rails API                       │
│      /api/v1/captures                │
└─────────────────────────────────────┘
```

## File Structure

```
chrome-extension/
├── manifest.json              # Extension configuration (Manifest V3)
├── popup/
│   ├── popup.html            # UI structure (capture + settings panels)
│   ├── popup.js              # Orchestration and state management
│   └── popup.css             # Styling
├── content/
│   └── content-script.js     # Content extraction logic
├── background/
│   └── service-worker.js     # API communication
├── lib/
│   └── readability.js        # Mozilla Readability library
└── assets/
    └── icons/                # Extension icons (16x16, 48x48, 128x128)
```

## Development

### Testing Content Extraction

Test on different types of pages:
- **News articles**: NYTimes, Medium, TechCrunch
- **Documentation**: GitHub repos, technical docs
- **Conversations**: Slack, Discord (if accessible)
- **Short content**: GitHub issues, Twitter/X posts

### Debugging

1. **Content Script Issues**: Open DevTools on the web page (F12)
2. **Popup Issues**: Right-click extension icon → "Inspect popup"
3. **Service Worker Issues**: Go to `chrome://extensions/` → "Service worker" link

### Console Logging

All components log to their respective consoles:
- Content script: Page DevTools console
- Popup: Popup DevTools console
- Service worker: Extension service worker console

## API Integration

### Request Format

```javascript
POST /api/v1/captures
Headers:
  Authorization: Bearer {api_token}
  Content-Type: application/json

Body:
{
  "capture": {
    "content": "Extracted article text...",
    "content_type": "article",
    "context": "Optional context",
    "tags": ["tag1", "tag2"],
    "obsidian_folder": "Captures",
    "metadata": {
      "url": "https://example.com/article",
      "domain": "example.com",
      "title": "Article Title",
      "author": "Author Name",
      "publishDate": "2025-12-18",
      "description": "Article excerpt",
      "siteName": "Site Name",
      "wordCount": 1234,
      "extractionMethod": "readability",
      "capturedAt": "2025-12-18T10:30:00Z"
    }
  }
}
```

### Response Handling

- **201**: Success - capture created
- **401**: Invalid API token
- **422**: Validation error
- **500**: Server error

## Troubleshooting

### Extension Not Loading
- Check that all required files exist
- Add PNG icons to `assets/icons/` directory
- Check Chrome DevTools console for errors

### Content Extraction Fails
- Check that the page has loaded completely
- Try selecting text manually before capturing
- Check content script console for errors

### API Errors
- Verify API endpoint is correct (include `/api/v1`)
- Confirm API token is valid
- Check Rails API is running and accessible
- Review service worker console for network errors

### Settings Not Saving
- Check Chrome storage permissions are granted
- Try reloading the extension

## Future Enhancements

- Keyboard shortcuts (Ctrl+Shift+C to capture)
- Context menu integration (right-click → Capture)
- Batch capture multiple tabs
- Offline queue with sync when API available
- Template selection in popup
- Recent captures history view

## Security

- API token stored securely in Chrome storage
- HTTPS recommended for production API endpoints
- Token never exposed in page context
- All API communication through service worker

## License

[Same as main project]
