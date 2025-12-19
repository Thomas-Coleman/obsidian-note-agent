// Content script for extracting page content and metadata
// Runs in the context of web pages to extract content using Readability and metadata

// Listen for messages from popup to extract content
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'extractContent') {
    const extractedData = extractPageContent();
    sendResponse(extractedData);
  }
  return true; // Keep message channel open for async response
});

/**
 * Main extraction orchestrator
 * Priority: 1. Text selection 2. Readability 3. Body text fallback
 */
function extractPageContent() {
  const url = window.location.href;
  const domain = window.location.hostname;
  const title = document.title;

  // Get selected text if any
  const selection = window.getSelection().toString().trim();

  let content = '';
  let extractionMethod = 'body'; // Default fallback
  let readabilityData = null;

  // Priority 1: Use selection if available
  if (selection.length > 0) {
    content = selection;
    extractionMethod = 'selection';
  } else {
    // Priority 2: Try Readability for article extraction
    try {
      const documentClone = document.cloneNode(true);
      const reader = new Readability(documentClone);
      readabilityData = reader.parse();

      if (readabilityData && readabilityData.textContent) {
        content = readabilityData.textContent;
        extractionMethod = 'readability';
      }
    } catch (error) {
      console.error('Readability extraction failed:', error);
    }

    // Priority 3: Fallback to body text
    if (!content) {
      content = document.body.innerText;
      extractionMethod = 'body';
    }
  }

  // Extract metadata from page
  const metadata = extractMetadata(url, domain, title, readabilityData);

  // Auto-detect content type
  const contentType = detectContentType(url, content, metadata);

  // Calculate word count
  const wordCount = content.split(/\s+/).filter(w => w.length > 0).length;

  return {
    content: content.trim(),
    metadata: {
      ...metadata,
      extractionMethod,
      wordCount,
      capturedAt: new Date().toISOString()
    },
    contentType,
    suggestedFolder: 'Captures'
  };
}

/**
 * Extract metadata from page meta tags and Readability data
 */
function extractMetadata(url, domain, title, readabilityData) {
  const metadata = {
    url,
    domain,
    title: readabilityData?.title || title
  };

  // Extract author
  const author = getMetaContent('author') ||
                 getMetaContent('article:author') ||
                 readabilityData?.byline;
  if (author) metadata.author = author;

  // Extract publish date
  const publishDate = getMetaContent('article:published_time') ||
                      getMetaContent('publishdate') ||
                      getMetaContent('date');
  if (publishDate) {
    metadata.publishDate = publishDate;
  }

  // Extract description/excerpt
  const description = getMetaContent('description') ||
                      getMetaContent('og:description') ||
                      readabilityData?.excerpt;
  if (description) metadata.description = description;

  // Extract site name
  const siteName = getMetaContent('og:site_name') ||
                   getMetaContent('application-name');
  if (siteName) metadata.siteName = siteName;

  // Extract image
  const image = getMetaContent('og:image') ||
                getMetaContent('twitter:image');
  if (image) metadata.image = image;

  // Extract keywords/tags
  const keywords = getMetaContent('keywords');
  if (keywords) {
    metadata.keywords = keywords.split(',').map(k => k.trim());
  }

  return metadata;
}

/**
 * Auto-detect content type based on URL, content, and metadata
 * Returns: 'article', 'conversation', 'note', or 'reference'
 */
function detectContentType(url, content, metadata) {
  const urlLower = url.toLowerCase();
  const wordCount = content.split(/\s+/).filter(w => w.length > 0).length;

  // Detect messaging/conversation platforms
  const conversationPlatforms = [
    'slack.com',
    'discord.com',
    'whatsapp.com',
    'telegram.org',
    'messages.google.com',
    'chat.google.com',
    'teams.microsoft.com'
  ];

  if (conversationPlatforms.some(platform => urlLower.includes(platform))) {
    return 'conversation';
  }

  // Detect article characteristics:
  // - Has publish date or author metadata
  // - Extracted via Readability successfully
  // - Has substantial word count (>300 words)
  const hasArticleMetadata = metadata.publishDate || metadata.author;
  const isSubstantial = wordCount > 300;

  if (metadata.extractionMethod === 'readability' && hasArticleMetadata && isSubstantial) {
    return 'article';
  }

  // Short content (<300 words) with no publish metadata = note
  if (wordCount < 300 && !hasArticleMetadata) {
    return 'note';
  }

  // Default to reference for everything else
  return 'reference';
}

/**
 * Helper to extract content from meta tags
 * Checks both name and property attributes
 */
function getMetaContent(name) {
  // Try name attribute first
  let meta = document.querySelector(`meta[name="${name}"]`);
  if (meta) return meta.getAttribute('content');

  // Try property attribute (for Open Graph tags)
  meta = document.querySelector(`meta[property="${name}"]`);
  if (meta) return meta.getAttribute('content');

  return null;
}
