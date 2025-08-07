/**
 * Ghost Wallet Hunter - Helper Utilities
 * =====================================
 *
 * General purpose utility functions for common operations,
 * data manipulation, and application logic.
 */

/**
 * Object Utilities
 */

/**
 * Deep clone an object
 * @param {any} obj - Object to clone
 * @returns {any} - Deep cloned object
 */
export const deepClone = (obj) => {
  if (obj === null || typeof obj !== 'object') return obj;
  if (obj instanceof Date) return new Date(obj);
  if (obj instanceof Array) return obj.map(item => deepClone(item));
  if (typeof obj === 'object') {
    const cloned = {};
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        cloned[key] = deepClone(obj[key]);
      }
    }
    return cloned;
  }
  return obj;
};

/**
 * Deep merge multiple objects
 * @param {...Object} objects - Objects to merge
 * @returns {Object} - Merged object
 */
export const deepMerge = (...objects) => {
  const isObject = (obj) => obj && typeof obj === 'object' && !Array.isArray(obj);

  return objects.reduce((prev, obj) => {
    if (!isObject(obj)) return prev;

    Object.keys(obj).forEach(key => {
      const prevValue = prev[key];
      const objValue = obj[key];

      if (isObject(prevValue) && isObject(objValue)) {
        prev[key] = deepMerge(prevValue, objValue);
      } else {
        prev[key] = objValue;
      }
    });

    return prev;
  }, {});
};

/**
 * Get nested object property safely
 * @param {Object} obj - Source object
 * @param {string} path - Property path (e.g., 'user.profile.name')
 * @param {any} defaultValue - Default value if property doesn't exist
 * @returns {any} - Property value or default
 */
export const getNestedProperty = (obj, path, defaultValue = null) => {
  if (!obj || typeof obj !== 'object') return defaultValue;

  const keys = path.split('.');
  let result = obj;

  for (const key of keys) {
    if (result === null || result === undefined || !(key in result)) {
      return defaultValue;
    }
    result = result[key];
  }

  return result;
};

/**
 * Set nested object property safely
 * @param {Object} obj - Target object
 * @param {string} path - Property path
 * @param {any} value - Value to set
 * @returns {Object} - Modified object
 */
export const setNestedProperty = (obj, path, value) => {
  const keys = path.split('.');
  const lastKey = keys.pop();
  let current = obj;

  for (const key of keys) {
    if (!(key in current) || typeof current[key] !== 'object') {
      current[key] = {};
    }
    current = current[key];
  }

  current[lastKey] = value;
  return obj;
};

/**
 * Remove empty properties from object
 * @param {Object} obj - Object to clean
 * @returns {Object} - Cleaned object
 */
export const removeEmptyProperties = (obj) => {
  if (!obj || typeof obj !== 'object') return obj;

  const cleaned = {};

  Object.keys(obj).forEach(key => {
    const value = obj[key];

    if (value !== null && value !== undefined && value !== '') {
      if (typeof value === 'object' && !Array.isArray(value)) {
        const nestedCleaned = removeEmptyProperties(value);
        if (Object.keys(nestedCleaned).length > 0) {
          cleaned[key] = nestedCleaned;
        }
      } else if (Array.isArray(value) && value.length > 0) {
        cleaned[key] = value;
      } else if (typeof value !== 'object') {
        cleaned[key] = value;
      }
    }
  });

  return cleaned;
};

/**
 * Array Utilities
 */

/**
 * Remove duplicates from array
 * @param {Array} array - Array with potential duplicates
 * @param {string} key - Property key for object comparison (optional)
 * @returns {Array} - Array without duplicates
 */
export const removeDuplicates = (array, key = null) => {
  if (!Array.isArray(array)) return [];

  if (key) {
    const seen = new Set();
    return array.filter(item => {
      const value = getNestedProperty(item, key);
      if (seen.has(value)) return false;
      seen.add(value);
      return true;
    });
  }

  return [...new Set(array)];
};

/**
 * Group array of objects by property
 * @param {Array} array - Array to group
 * @param {string} key - Property key to group by
 * @returns {Object} - Grouped object
 */
export const groupBy = (array, key) => {
  if (!Array.isArray(array)) return {};

  return array.reduce((groups, item) => {
    const value = getNestedProperty(item, key);
    const groupKey = value || 'undefined';

    if (!groups[groupKey]) {
      groups[groupKey] = [];
    }

    groups[groupKey].push(item);
    return groups;
  }, {});
};

/**
 * Sort array of objects by property
 * @param {Array} array - Array to sort
 * @param {string} key - Property key to sort by
 * @param {string} direction - Sort direction ('asc' or 'desc')
 * @returns {Array} - Sorted array
 */
export const sortBy = (array, key, direction = 'asc') => {
  if (!Array.isArray(array)) return [];

  return [...array].sort((a, b) => {
    const valueA = getNestedProperty(a, key);
    const valueB = getNestedProperty(b, key);

    if (valueA === valueB) return 0;

    let comparison = 0;
    if (valueA > valueB) {
      comparison = 1;
    } else if (valueA < valueB) {
      comparison = -1;
    }

    return direction === 'desc' ? comparison * -1 : comparison;
  });
};

/**
 * Paginate array
 * @param {Array} array - Array to paginate
 * @param {number} page - Page number (1-based)
 * @param {number} pageSize - Items per page
 * @returns {Object} - Pagination result
 */
export const paginate = (array, page = 1, pageSize = 10) => {
  if (!Array.isArray(array)) {
    return {
      data: [],
      currentPage: 1,
      totalPages: 0,
      totalItems: 0,
      hasNext: false,
      hasPrev: false
    };
  }

  const totalItems = array.length;
  const totalPages = Math.ceil(totalItems / pageSize);
  const currentPage = Math.max(1, Math.min(page, totalPages));
  const startIndex = (currentPage - 1) * pageSize;
  const endIndex = startIndex + pageSize;

  return {
    data: array.slice(startIndex, endIndex),
    currentPage,
    totalPages,
    totalItems,
    hasNext: currentPage < totalPages,
    hasPrev: currentPage > 1,
    startIndex: startIndex + 1,
    endIndex: Math.min(endIndex, totalItems)
  };
};

/**
 * String Utilities
 */

/**
 * Generate random string
 * @param {number} length - String length
 * @param {string} charset - Character set to use
 * @returns {string} - Random string
 */
export const generateRandomString = (length = 8, charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789') => {
  let result = '';
  for (let i = 0; i < length; i++) {
    result += charset.charAt(Math.floor(Math.random() * charset.length));
  }
  return result;
};

/**
 * Generate UUID v4
 * @returns {string} - UUID string
 */
export const generateUUID = () => {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
};

/**
 * Slugify string (URL-friendly)
 * @param {string} text - Text to slugify
 * @returns {string} - Slugified string
 */
export const slugify = (text) => {
  if (!text || typeof text !== 'string') return '';

  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
};

/**
 * Extract hashtags from text
 * @param {string} text - Text to analyze
 * @returns {Array} - Array of hashtags
 */
export const extractHashtags = (text) => {
  if (!text || typeof text !== 'string') return [];

  const hashtags = text.match(/#\w+/g);
  return hashtags ? hashtags.map(tag => tag.toLowerCase()) : [];
};

/**
 * Number Utilities
 */

/**
 * Generate random number between min and max
 * @param {number} min - Minimum value
 * @param {number} max - Maximum value
 * @returns {number} - Random number
 */
export const randomBetween = (min, max) => {
  return Math.random() * (max - min) + min;
};

/**
 * Generate random integer between min and max (inclusive)
 * @param {number} min - Minimum value
 * @param {number} max - Maximum value
 * @returns {number} - Random integer
 */
export const randomIntBetween = (min, max) => {
  return Math.floor(Math.random() * (max - min + 1)) + min;
};

/**
 * Clamp number between min and max
 * @param {number} value - Value to clamp
 * @param {number} min - Minimum value
 * @param {number} max - Maximum value
 * @returns {number} - Clamped value
 */
export const clamp = (value, min, max) => {
  return Math.min(Math.max(value, min), max);
};

/**
 * Round number to specified decimal places
 * @param {number} value - Value to round
 * @param {number} decimals - Decimal places
 * @returns {number} - Rounded value
 */
export const roundTo = (value, decimals = 2) => {
  const factor = Math.pow(10, decimals);
  return Math.round(value * factor) / factor;
};

/**
 * Time Utilities
 */

/**
 * Delay execution for specified milliseconds
 * @param {number} ms - Milliseconds to delay
 * @returns {Promise} - Promise that resolves after delay
 */
export const delay = (ms) => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

/**
 * Debounce function execution
 * @param {Function} func - Function to debounce
 * @param {number} delay - Delay in milliseconds
 * @returns {Function} - Debounced function
 */
export const debounce = (func, delay) => {
  let timeoutId;

  return function(...args) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => func.apply(this, args), delay);
  };
};

/**
 * Throttle function execution
 * @param {Function} func - Function to throttle
 * @param {number} delay - Delay in milliseconds
 * @returns {Function} - Throttled function
 */
export const throttle = (func, delay) => {
  let lastCall = 0;

  return function(...args) {
    const now = Date.now();
    if (now - lastCall >= delay) {
      lastCall = now;
      return func.apply(this, args);
    }
  };
};

/**
 * Retry function with exponential backoff
 * @param {Function} func - Function to retry
 * @param {number} maxRetries - Maximum retry attempts
 * @param {number} baseDelay - Base delay in milliseconds
 * @returns {Promise} - Promise that resolves with function result
 */
export const retryWithBackoff = async (func, maxRetries = 3, baseDelay = 1000) => {
  let lastError;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await func();
    } catch (error) {
      lastError = error;

      if (attempt === maxRetries) {
        throw lastError;
      }

      const delayMs = baseDelay * Math.pow(2, attempt);
      await delay(delayMs);
    }
  }
};

/**
 * URL Utilities
 */

/**
 * Parse query string to object
 * @param {string} queryString - Query string to parse
 * @returns {Object} - Parsed query parameters
 */
export const parseQueryString = (queryString) => {
  if (!queryString || typeof queryString !== 'string') return {};

  const params = {};
  const queries = queryString.replace(/^\?/, '').split('&');

  queries.forEach(query => {
    const [key, value] = query.split('=');
    if (key) {
      params[decodeURIComponent(key)] = value ? decodeURIComponent(value) : '';
    }
  });

  return params;
};

/**
 * Convert object to query string
 * @param {Object} params - Parameters object
 * @returns {string} - Query string
 */
export const buildQueryString = (params) => {
  if (!params || typeof params !== 'object') return '';

  const queries = Object.keys(params)
    .filter(key => params[key] !== null && params[key] !== undefined)
    .map(key => {
      const value = params[key];
      return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
    });

  return queries.length > 0 ? `?${queries.join('&')}` : '';
};

/**
 * Local Storage Utilities
 */

/**
 * Safe local storage operations
 */
export const storage = {
  /**
   * Get item from localStorage with error handling
   * @param {string} key - Storage key
   * @param {any} defaultValue - Default value if key doesn't exist
   * @returns {any} - Stored value or default
   */
  get: (key, defaultValue = null) => {
    try {
      const item = localStorage.getItem(key);
      return item ? JSON.parse(item) : defaultValue;
    } catch (error) {
      console.warn('Error reading from localStorage:', error);
      return defaultValue;
    }
  },

  /**
   * Set item in localStorage with error handling
   * @param {string} key - Storage key
   * @param {any} value - Value to store
   * @returns {boolean} - Success status
   */
  set: (key, value) => {
    try {
      localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch (error) {
      console.warn('Error writing to localStorage:', error);
      return false;
    }
  },

  /**
   * Remove item from localStorage
   * @param {string} key - Storage key
   * @returns {boolean} - Success status
   */
  remove: (key) => {
    try {
      localStorage.removeItem(key);
      return true;
    } catch (error) {
      console.warn('Error removing from localStorage:', error);
      return false;
    }
  },

  /**
   * Clear all localStorage
   * @returns {boolean} - Success status
   */
  clear: () => {
    try {
      localStorage.clear();
      return true;
    } catch (error) {
      console.warn('Error clearing localStorage:', error);
      return false;
    }
  }
};

/**
 * Color Utilities
 */

/**
 * Convert hex color to rgba
 * @param {string} hex - Hex color code
 * @param {number} alpha - Alpha value (0-1)
 * @returns {string} - RGBA color string
 */
export const hexToRgba = (hex, alpha = 1) => {
  if (!hex || typeof hex !== 'string') return '';

  const cleanHex = hex.replace('#', '');
  const r = parseInt(cleanHex.substring(0, 2), 16);
  const g = parseInt(cleanHex.substring(2, 4), 16);
  const b = parseInt(cleanHex.substring(4, 6), 16);

  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};

/**
 * Get contrasting text color for background
 * @param {string} backgroundColor - Background color (hex)
 * @returns {string} - Contrasting text color
 */
export const getContrastColor = (backgroundColor) => {
  if (!backgroundColor) return '#000000';

  const hex = backgroundColor.replace('#', '');
  const r = parseInt(hex.substring(0, 2), 16);
  const g = parseInt(hex.substring(2, 4), 16);
  const b = parseInt(hex.substring(4, 6), 16);

  // Calculate relative luminance
  const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

  return luminance > 0.5 ? '#000000' : '#ffffff';
};

/**
 * Error Handling Utilities
 */

/**
 * Safe function execution with error handling
 * @param {Function} func - Function to execute
 * @param {any} defaultValue - Default return value on error
 * @returns {any} - Function result or default value
 */
export const safeExecute = (func, defaultValue = null) => {
  try {
    return func();
  } catch (error) {
    console.warn('Safe execution error:', error);
    return defaultValue;
  }
};

/**
 * Extract error message from various error types
 * @param {any} error - Error object or value
 * @returns {string} - Readable error message
 */
export const getErrorMessage = (error) => {
  if (!error) return 'Unknown error';

  if (typeof error === 'string') return error;

  if (error.message) return error.message;

  if (error.response?.data?.message) return error.response.data.message;

  if (error.response?.statusText) return error.response.statusText;

  return 'An unexpected error occurred';
};

export default {
  // Object utilities
  deepClone,
  deepMerge,
  getNestedProperty,
  setNestedProperty,
  removeEmptyProperties,

  // Array utilities
  removeDuplicates,
  groupBy,
  sortBy,
  paginate,

  // String utilities
  generateRandomString,
  generateUUID,
  slugify,
  extractHashtags,

  // Number utilities
  randomBetween,
  randomIntBetween,
  clamp,
  roundTo,

  // Time utilities
  delay,
  debounce,
  throttle,
  retryWithBackoff,

  // URL utilities
  parseQueryString,
  buildQueryString,

  // Storage utilities
  storage,

  // Color utilities
  hexToRgba,
  getContrastColor,

  // Error utilities
  safeExecute,
  getErrorMessage
};
