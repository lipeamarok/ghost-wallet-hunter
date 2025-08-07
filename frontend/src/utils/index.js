/**
 * Ghost Wallet Hunter - Utils Export Index
 * =======================================
 *
 * Centralized export for all utility functions.
 * Provides organized access to validation, formatting, and helper utilities.
 */

// Validation Utilities
export {
  // Constants
  BLOCKCHAIN_NETWORKS,
  VALIDATION_MESSAGES,

  // Address Validation
  isValidEthereumAddress,
  isValidBitcoinAddress,
  isValidSolanaAddress,
  isValidCardanoAddress,
  detectAddressNetwork,
  validateWalletAddress,

  // Transaction Validation
  validateTransactionHash,

  // Data Validation
  isValidEmail,
  isValidURL,
  isValidNumber,
  isValidPositiveInteger,

  // Input Sanitization
  sanitizeWalletAddress,
  sanitizeTextInput,

  // Form Validation
  validateFormData,

  // Default Export
  default as ValidationUtils
} from './validation.js';

// Formatting Utilities
export {
  // Number Formatting
  formatLargeNumber,
  formatCurrency,
  formatCrypto,
  formatPercentage,
  formatDecimalAsPercentage,

  // Address Formatting
  formatWalletAddress,
  formatTransactionHash,

  // Date Formatting
  formatDate,
  formatDateTime,
  formatTimeAgo,
  formatDuration,

  // Status Formatting
  formatInvestigationStatus,
  formatRiskLevel,
  formatConfidence,

  // Data Formatting
  formatJSON,
  formatFileSize,
  formatArray,

  // Text Formatting
  capitalize,
  camelToTitle,
  snakeToTitle,
  truncateText,

  // URL Formatting
  formatExplorerURL,

  // Composite Formatters
  formatTransactionSummary,
  formatInvestigationSummary,

  // Default Export
  default as FormatUtils
} from './formatters.js';

// Helper Utilities
export {
  // Object Utilities
  deepClone,
  deepMerge,
  getNestedProperty,
  setNestedProperty,
  removeEmptyProperties,

  // Array Utilities
  removeDuplicates,
  groupBy,
  sortBy,
  paginate,

  // String Utilities
  generateRandomString,
  generateUUID,
  slugify,
  extractHashtags,

  // Number Utilities
  randomBetween,
  randomIntBetween,
  clamp,
  roundTo,

  // Time Utilities
  delay,
  debounce,
  throttle,
  retryWithBackoff,

  // URL Utilities
  parseQueryString,
  buildQueryString,

  // Storage Utilities
  storage,

  // Color Utilities
  hexToRgba,
  getContrastColor,

  // Error Utilities
  safeExecute,
  getErrorMessage,

  // Default Export
  default as HelperUtils
} from './helpers.js';

/**
 * Combined Utility Collections
 */

// Validation Collection
export const VALIDATION = {
  // Networks
  networks: BLOCKCHAIN_NETWORKS,
  messages: VALIDATION_MESSAGES,

  // Address Validators
  address: {
    ethereum: isValidEthereumAddress,
    bitcoin: isValidBitcoinAddress,
    solana: isValidSolanaAddress,
    cardano: isValidCardanoAddress,
    detect: detectAddressNetwork,
    validate: validateWalletAddress
  },

  // Transaction Validators
  transaction: {
    validate: validateTransactionHash
  },

  // Data Validators
  data: {
    email: isValidEmail,
    url: isValidURL,
    number: isValidNumber,
    positiveInteger: isValidPositiveInteger
  },

  // Sanitizers
  sanitize: {
    address: sanitizeWalletAddress,
    text: sanitizeTextInput
  },

  // Form Validation
  form: validateFormData
};

// Formatting Collection
export const FORMATTING = {
  // Number Formatters
  number: {
    large: formatLargeNumber,
    currency: formatCurrency,
    crypto: formatCrypto,
    percentage: formatPercentage,
    decimalAsPercentage: formatDecimalAsPercentage
  },

  // Address Formatters
  address: {
    wallet: formatWalletAddress,
    transaction: formatTransactionHash
  },

  // Date Formatters
  date: {
    format: formatDate,
    dateTime: formatDateTime,
    timeAgo: formatTimeAgo,
    duration: formatDuration
  },

  // Status Formatters
  status: {
    investigation: formatInvestigationStatus,
    risk: formatRiskLevel,
    confidence: formatConfidence
  },

  // Data Formatters
  data: {
    json: formatJSON,
    fileSize: formatFileSize,
    array: formatArray
  },

  // Text Formatters
  text: {
    capitalize: capitalize,
    camelToTitle: camelToTitle,
    snakeToTitle: snakeToTitle,
    truncate: truncateText
  },

  // URL Formatters
  url: {
    explorer: formatExplorerURL
  },

  // Composite Formatters
  composite: {
    transaction: formatTransactionSummary,
    investigation: formatInvestigationSummary
  }
};

// Helper Collection
export const HELPERS = {
  // Object Helpers
  object: {
    deepClone,
    deepMerge,
    getNestedProperty,
    setNestedProperty,
    removeEmptyProperties
  },

  // Array Helpers
  array: {
    removeDuplicates,
    groupBy,
    sortBy,
    paginate
  },

  // String Helpers
  string: {
    randomString: generateRandomString,
    uuid: generateUUID,
    slugify,
    extractHashtags
  },

  // Number Helpers
  number: {
    randomBetween,
    randomIntBetween,
    clamp,
    roundTo
  },

  // Time Helpers
  time: {
    delay,
    debounce,
    throttle,
    retryWithBackoff
  },

  // URL Helpers
  url: {
    parseQuery: parseQueryString,
    buildQuery: buildQueryString
  },

  // Storage Helpers
  storage: storage,

  // Color Helpers
  color: {
    hexToRgba,
    getContrastColor
  },

  // Error Helpers
  error: {
    safeExecute,
    getErrorMessage
  }
};

/**
 * Common Utility Patterns
 */

// Wallet Analysis Utilities
export const WALLET_UTILS = {
  /**
   * Complete wallet address validation and formatting
   */
  processAddress: (address, network = null) => {
    const validation = validateWalletAddress(address, network);
    if (!validation.isValid) {
      throw new Error(validation.error);
    }

    return {
      original: address,
      sanitized: sanitizeWalletAddress(address),
      formatted: formatWalletAddress(address),
      network: validation.network,
      format: validation.format,
      explorerURL: formatExplorerURL(validation.network, 'address', address)
    };
  },

  /**
   * Process transaction hash
   */
  processTransaction: (hash, network = null) => {
    const validation = validateTransactionHash(hash, network);
    if (!validation.isValid) {
      throw new Error(validation.error);
    }

    return {
      original: hash,
      formatted: formatTransactionHash(hash),
      network: validation.network,
      explorerURL: formatExplorerURL(validation.network, 'tx', hash)
    };
  }
};

// Investigation Utilities
export const INVESTIGATION_UTILS = {
  /**
   * Process investigation results for display
   */
  processResults: (investigation) => {
    return {
      ...formatInvestigationSummary(investigation),
      walletInfo: WALLET_UTILS.processAddress(investigation.walletAddress),
      formattedActivities: investigation.flaggedActivities?.map(activity => ({
        ...activity,
        formattedSeverity: activity.severity >= 8 ? 'Critical' :
                          activity.severity >= 6 ? 'High' :
                          activity.severity >= 4 ? 'Medium' :
                          activity.severity >= 2 ? 'Low' : 'Info',
        timeAgo: formatTimeAgo(activity.timestamp)
      })) || []
    };
  },

  /**
   * Calculate investigation metrics
   */
  calculateMetrics: (investigations) => {
    if (!Array.isArray(investigations) || investigations.length === 0) {
      return {
        total: 0,
        completed: 0,
        failed: 0,
        averageDuration: 0,
        successRate: 0,
        riskDistribution: {}
      };
    }

    const completed = investigations.filter(inv => inv.status === 'completed');
    const failed = investigations.filter(inv => inv.status === 'failed');

    const averageDuration = completed.length > 0
      ? completed.reduce((sum, inv) => sum + (inv.duration || 0), 0) / completed.length
      : 0;

    const successRate = investigations.length > 0
      ? (completed.length / investigations.length) * 100
      : 0;

    const riskDistribution = groupBy(completed, 'riskLevel');

    return {
      total: investigations.length,
      completed: completed.length,
      failed: failed.length,
      averageDuration: Math.round(averageDuration),
      successRate: roundTo(successRate, 1),
      riskDistribution: Object.keys(riskDistribution).reduce((acc, level) => {
        acc[level] = riskDistribution[level].length;
        return acc;
      }, {})
    };
  }
};

// Performance Utilities
export const PERFORMANCE_UTILS = {
  /**
   * Measure function execution time
   */
  measureTime: async (func, name = 'Operation') => {
    const start = performance.now();
    const result = await func();
    const end = performance.now();

    console.log(`${name} took ${formatDuration(end - start)}`);
    return result;
  },

  /**
   * Create performance-optimized debounced search
   */
  createDebouncedSearch: (searchFunction, delay = 300) => {
    return debounce(async (query) => {
      if (!query || query.length < 2) return [];

      return await searchFunction(query);
    }, delay);
  },

  /**
   * Batch process large arrays
   */
  batchProcess: async (items, processor, batchSize = 10, delay = 100) => {
    const results = [];

    for (let i = 0; i < items.length; i += batchSize) {
      const batch = items.slice(i, i + batchSize);
      const batchResults = await Promise.all(batch.map(processor));
      results.push(...batchResults);

      // Add delay between batches to prevent overwhelming
      if (i + batchSize < items.length && delay > 0) {
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }

    return results;
  }
};

/**
 * Default Export - All Utils Combined
 */
export default {
  // Individual utility modules
  ValidationUtils,
  FormatUtils,
  HelperUtils,

  // Organized collections
  VALIDATION,
  FORMATTING,
  HELPERS,

  // Specialized utilities
  WALLET_UTILS,
  INVESTIGATION_UTILS,
  PERFORMANCE_UTILS,

  // Quick access to common functions
  validate: VALIDATION,
  format: FORMATTING,
  helpers: HELPERS,
  wallet: WALLET_UTILS,
  investigation: INVESTIGATION_UTILS,
  performance: PERFORMANCE_UTILS
};
