// Popup orchestration logic
// Handles UI state, user interactions, and communication with content script and service worker

// State management
let extractedData = null;
let isCapturing = false;
let settings = {
  apiEndpoint: 'http://localhost/api/v1',
  apiToken: ''
};

// DOM elements
const capturePanel = document.getElementById('capturePanel');
const settingsPanel = document.getElementById('settingsPanel');
const loadingState = document.getElementById('loadingState');
const captureForm = document.getElementById('captureForm');
const statusMessage = document.getElementById('statusMessage');
const settingsStatus = document.getElementById('settingsStatus');

// Capture panel elements
const contentTypeSelect = document.getElementById('contentType');
const contextTextarea = document.getElementById('context');
const tagsInput = document.getElementById('tags');
const obsidianFolderInput = document.getElementById('obsidianFolder');
const skipProcessingCheckbox = document.getElementById('skipProcessing');
const captureBtn = document.getElementById('captureBtn');
const metadataToggle = document.getElementById('metadataToggle');
const metadataContent = document.getElementById('metadataContent');

// Settings panel elements
const apiEndpointInput = document.getElementById('apiEndpoint');
const apiTokenInput = document.getElementById('apiToken');
const saveSettingsBtn = document.getElementById('saveSettingsBtn');

// Navigation buttons
const settingsBtn = document.getElementById('settingsBtn');
const backBtn = document.getElementById('backBtn');

// Initialize on popup open
document.addEventListener('DOMContentLoaded', async () => {
  await loadSettings();

  // Setup event listeners first (needed for settings panel)
  setupEventListeners();

  // Check if settings are configured
  if (!settings.apiToken || !settings.apiEndpoint) {
    showSettingsPanel();
    showStatus(settingsStatus, 'Please configure your API endpoint and token', 'info');
    return;
  }

  // Extract content from current page
  await extractContent();
});

/**
 * Load settings from Chrome storage
 */
async function loadSettings() {
  try {
    const result = await chrome.storage.local.get(['apiEndpoint', 'apiToken']);
    if (result.apiEndpoint) settings.apiEndpoint = result.apiEndpoint;
    if (result.apiToken) settings.apiToken = result.apiToken;

    // Populate settings form
    apiEndpointInput.value = settings.apiEndpoint;
    apiTokenInput.value = settings.apiToken;
  } catch (error) {
    console.error('Error loading settings:', error);
  }
}

/**
 * Save settings to Chrome storage
 */
async function saveSettings() {
  const endpoint = apiEndpointInput.value.trim();
  const token = apiTokenInput.value.trim();

  if (!endpoint || !token) {
    showStatus(settingsStatus, 'Both API endpoint and token are required', 'error');
    return;
  }

  try {
    await chrome.storage.local.set({
      apiEndpoint: endpoint,
      apiToken: token
    });

    settings.apiEndpoint = endpoint;
    settings.apiToken = token;

    showStatus(settingsStatus, 'Settings saved successfully! Navigate to a web page to start capturing.', 'success');
  } catch (error) {
    console.error('Error saving settings:', error);
    showStatus(settingsStatus, 'Failed to save settings', 'error');
  }
}

/**
 * Extract content from the current page
 */
async function extractContent() {
  try {
    loadingState.classList.remove('hidden');
    captureForm.classList.add('hidden');
    statusMessage.classList.add('hidden');

    // Get active tab
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

    // Check if this is a valid page for content extraction
    if (!tab.url || tab.url.startsWith('chrome://') || tab.url.startsWith('chrome-extension://') ||
        tab.url.startsWith('edge://') || tab.url.startsWith('about:')) {
      loadingState.classList.add('hidden');
      showStatus(statusMessage, 'Cannot capture from this page. Please navigate to a website.', 'info');
      return;
    }

    // Send message to content script to extract content
    const response = await chrome.tabs.sendMessage(tab.id, { action: 'extractContent' });

    extractedData = response;

    // Populate form with extracted data
    populateForm();

    loadingState.classList.add('hidden');
    captureForm.classList.remove('hidden');
  } catch (error) {
    console.error('Error extracting content:', error);
    loadingState.classList.add('hidden');
    showStatus(statusMessage, 'Failed to extract content. Try reloading the page.', 'error');
  }
}

/**
 * Populate form with extracted data
 */
function populateForm() {
  if (!extractedData) return;

  // Set content type
  contentTypeSelect.value = extractedData.contentType || 'note';

  // Set folder
  obsidianFolderInput.value = extractedData.suggestedFolder || 'Captures';

  // Auto-populate context with source URL
  const sourceUrl = extractedData.metadata.url || '';
  if (sourceUrl) {
    contextTextarea.value = `Source: ${sourceUrl}\n\n`;
  }

  // Populate metadata preview
  document.getElementById('metadataUrl').textContent = extractedData.metadata.url || 'N/A';
  document.getElementById('metadataDomain').textContent = extractedData.metadata.domain || 'N/A';
  document.getElementById('metadataTitle').textContent = extractedData.metadata.title || 'N/A';
  document.getElementById('metadataMethod').textContent = extractedData.metadata.extractionMethod || 'N/A';
  document.getElementById('metadataWordCount').textContent = extractedData.metadata.wordCount || '0';

  // Show content preview (first 500 chars)
  const preview = extractedData.content.substring(0, 500);
  const contentPreview = document.getElementById('contentPreview');
  contentPreview.textContent = preview + (extractedData.content.length > 500 ? '...' : '');

  // Pre-populate tags if available from metadata
  if (extractedData.metadata.keywords && extractedData.metadata.keywords.length > 0) {
    tagsInput.value = extractedData.metadata.keywords.join(', ');
  }
}

/**
 * Capture content and send to API
 */
async function captureContent() {
  if (isCapturing || !extractedData) return;

  // Validate required fields
  const contentType = contentTypeSelect.value;
  const content = extractedData.content;

  if (!contentType || !content) {
    showStatus(statusMessage, 'Content and content type are required', 'error');
    return;
  }

  isCapturing = true;
  captureBtn.disabled = true;
  captureBtn.textContent = 'Saving...';

  // Build capture payload
  const tags = tagsInput.value
    .split(',')
    .map(t => t.trim())
    .filter(t => t.length > 0);

  const payload = {
    capture: {
      content: content,
      content_type: contentType,
      context: contextTextarea.value.trim() || undefined,
      tags: tags.length > 0 ? tags : undefined,
      obsidian_folder: obsidianFolderInput.value.trim() || 'Captures',
      metadata: extractedData.metadata,
      skip_processing: skipProcessingCheckbox.checked
    }
  };

  try {
    // Send to service worker to make API call
    const response = await chrome.runtime.sendMessage({
      action: 'createCapture',
      payload: payload,
      apiEndpoint: settings.apiEndpoint,
      apiToken: settings.apiToken
    });

    if (response.success) {
      showStatus(statusMessage, 'Captured successfully! Saved to Obsidian.', 'success');
      captureBtn.textContent = 'Capture Another';
      captureBtn.disabled = false;

      // Reset for another capture
      setTimeout(() => {
        resetForm();
      }, 2000);
    } else {
      showStatus(statusMessage, response.error || 'Failed to capture', 'error');
      captureBtn.textContent = 'Save to Obsidian';
      captureBtn.disabled = false;
    }
  } catch (error) {
    console.error('Error capturing content:', error);
    showStatus(statusMessage, 'Failed to capture: ' + error.message, 'error');
    captureBtn.textContent = 'Save to Obsidian';
    captureBtn.disabled = false;
  } finally {
    isCapturing = false;
  }
}

/**
 * Reset form for another capture
 */
function resetForm() {
  contextTextarea.value = '';
  tagsInput.value = '';
  statusMessage.classList.add('hidden');
  captureBtn.textContent = 'Save to Obsidian';

  // Re-extract content for a fresh capture
  extractContent();
}

/**
 * Setup all event listeners
 */
function setupEventListeners() {
  // Navigation
  settingsBtn.addEventListener('click', showSettingsPanel);
  backBtn.addEventListener('click', showCapturePanel);

  // Capture
  captureBtn.addEventListener('click', captureContent);

  // Settings
  saveSettingsBtn.addEventListener('click', saveSettings);

  // Metadata toggle
  metadataToggle.addEventListener('click', () => {
    metadataContent.classList.toggle('hidden');
    metadataToggle.classList.toggle('expanded');
  });
}

/**
 * Show status message
 */
function showStatus(element, message, type = 'info') {
  element.textContent = message;
  element.className = `status-message ${type}`;
  element.classList.remove('hidden');
}

/**
 * Panel navigation
 */
function showCapturePanel() {
  capturePanel.classList.add('active');
  settingsPanel.classList.remove('active');
}

function showSettingsPanel() {
  settingsPanel.classList.add('active');
  capturePanel.classList.remove('active');
}
