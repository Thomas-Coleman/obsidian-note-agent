// Service worker for background tasks and API communication
// Handles making authenticated HTTP requests to the Rails API

// Listen for messages from popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'createCapture') {
    // Handle capture creation asynchronously
    createCapture(request.payload, request.apiEndpoint, request.apiToken)
      .then(result => sendResponse(result))
      .catch(error => sendResponse({ success: false, error: error.message }));

    return true; // Keep message channel open for async response
  }
});

/**
 * Create a capture by sending POST request to Rails API
 */
async function createCapture(payload, apiEndpoint, apiToken) {
  try {
    const url = `${apiEndpoint}/captures`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiToken}`
      },
      body: JSON.stringify(payload)
    });

    // Handle different response status codes
    if (response.status === 201) {
      // Success - capture created
      const data = await response.json();
      return {
        success: true,
        data: data
      };
    } else if (response.status === 401) {
      // Unauthorized - invalid API token
      return {
        success: false,
        error: 'Invalid API token. Please check your settings.'
      };
    } else if (response.status === 422) {
      // Validation error
      const data = await response.json();
      const errors = data.errors ? data.errors.join(', ') : 'Validation failed';
      return {
        success: false,
        error: `Validation error: ${errors}`
      };
    } else if (response.status === 500) {
      // Server error
      return {
        success: false,
        error: 'Server error. Please try again later.'
      };
    } else {
      // Other errors
      return {
        success: false,
        error: `Request failed with status ${response.status}`
      };
    }
  } catch (error) {
    // Network error or other exception
    console.error('API request error:', error);

    if (error.name === 'TypeError' && error.message.includes('fetch')) {
      return {
        success: false,
        error: 'Network error. Check your connection and API endpoint.'
      };
    }

    return {
      success: false,
      error: error.message || 'Unknown error occurred'
    };
  }
}

/**
 * Log extension installation/update
 */
chrome.runtime.onInstalled.addListener((details) => {
  if (details.reason === 'install') {
    console.log('Obsidian Note Agent extension installed');
  } else if (details.reason === 'update') {
    console.log('Obsidian Note Agent extension updated');
  }
});
