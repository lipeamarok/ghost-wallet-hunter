/**
 * Ghost Wallet Hunter - Data Formatters
 * ====================================
 *
 * Comprehensive formatting utilities for displaying data
 * in user-friendly formats across the application.
 */

/**
 * Number Formatting
 */

/**
 * Format large numbers with appropriate units (K, M, B, T)
 * @param {number} value - Number to format
 * @param {number} decimals - Number of decimal places
 * @returns {string} - Formatted number string
 */
export const formatLargeNumber = (value, decimals = 1) => {
  if (!value || isNaN(value)) return '0';

  const num = Math.abs(Number(value));
  const sign = value < 0 ? '-' : '';

  if (num >= 1e12) {
    return sign + (num / 1e12).toFixed(decimals) + 'T';
  }
  if (num >= 1e9) {
    return sign + (num / 1e9).toFixed(decimals) + 'B';
  }
  if (num >= 1e6) {
    return sign + (num / 1e6).toFixed(decimals) + 'M';
  }
  if (num >= 1e3) {
    return sign + (num / 1e3).toFixed(decimals) + 'K';
  }

  return sign + num.toFixed(decimals);
};

/**
 * Format currency values
 * @param {number} value - Currency value
 * @param {string} currency - Currency code (USD, EUR, etc.)
 * @param {number} decimals - Number of decimal places
 * @returns {string} - Formatted currency string
 */
export const formatCurrency = (value, currency = 'USD', decimals = 2) => {
  if (!value || isNaN(value)) return `$0.00`;

  const formatter = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency,
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals
  });

  return formatter.format(value);
};

/**
 * Format cryptocurrency values
 * @param {number} value - Crypto value
 * @param {string} symbol - Crypto symbol (ETH, BTC, etc.)
 * @param {number} decimals - Number of decimal places
 * @returns {string} - Formatted crypto string
 */
export const formatCrypto = (value, symbol = 'ETH', decimals = 4) => {
  if (!value || isNaN(value)) return `0 ${symbol}`;

  const num = Number(value);

  // For very small amounts, show more decimals
  if (num < 0.001 && num > 0) {
    return `${num.toFixed(8)} ${symbol}`;
  }

  return `${num.toFixed(decimals)} ${symbol}`;
};

/**
 * Format percentage values
 * @param {number} value - Percentage value (0-100)
 * @param {number} decimals - Number of decimal places
 * @returns {string} - Formatted percentage string
 */
export const formatPercentage = (value, decimals = 1) => {
  if (value === null || value === undefined || isNaN(value)) return '0%';

  const num = Number(value);
  return `${num.toFixed(decimals)}%`;
};

/**
 * Format decimal as percentage
 * @param {number} value - Decimal value (0-1)
 * @param {number} decimals - Number of decimal places
 * @returns {string} - Formatted percentage string
 */
export const formatDecimalAsPercentage = (value, decimals = 1) => {
  if (value === null || value === undefined || isNaN(value)) return '0%';

  const percentage = Number(value) * 100;
  return formatPercentage(percentage, decimals);
};

/**
 * Address Formatting
 */

/**
 * Truncate wallet address for display
 * @param {string} address - Full wallet address
 * @param {number} startChars - Characters to show at start
 * @param {number} endChars - Characters to show at end
 * @returns {string} - Truncated address
 */
export const formatWalletAddress = (address, startChars = 6, endChars = 4) => {
  if (!address || typeof address !== 'string') return '';

  if (address.length <= startChars + endChars) {
    return address;
  }

  return `${address.slice(0, startChars)}...${address.slice(-endChars)}`;
};

/**
 * Format transaction hash for display
 * @param {string} hash - Transaction hash
 * @param {number} startChars - Characters to show at start
 * @param {number} endChars - Characters to show at end
 * @returns {string} - Truncated hash
 */
export const formatTransactionHash = (hash, startChars = 8, endChars = 6) => {
  return formatWalletAddress(hash, startChars, endChars);
};

/**
 * Date and Time Formatting
 */

/**
 * Format timestamp to readable date
 * @param {number|string|Date} timestamp - Timestamp to format
 * @param {Object} options - Formatting options
 * @returns {string} - Formatted date string
 */
export const formatDate = (timestamp, options = {}) => {
  if (!timestamp) return '';

  const date = new Date(timestamp);
  if (isNaN(date.getTime())) return 'Invalid Date';

  const defaultOptions = {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    ...options
  };

  return date.toLocaleDateString('en-US', defaultOptions);
};

/**
 * Format timestamp to readable date and time
 * @param {number|string|Date} timestamp - Timestamp to format
 * @param {Object} options - Formatting options
 * @returns {string} - Formatted datetime string
 */
export const formatDateTime = (timestamp, options = {}) => {
  if (!timestamp) return '';

  const date = new Date(timestamp);
  if (isNaN(date.getTime())) return 'Invalid Date';

  const defaultOptions = {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    ...options
  };

  return date.toLocaleString('en-US', defaultOptions);
};

/**
 * Format relative time (time ago)
 * @param {number|string|Date} timestamp - Timestamp to format
 * @returns {string} - Relative time string
 */
export const formatTimeAgo = (timestamp) => {
  if (!timestamp) return '';

  const date = new Date(timestamp);
  if (isNaN(date.getTime())) return 'Invalid Date';

  const now = new Date();
  const diffInSeconds = Math.floor((now - date) / 1000);

  if (diffInSeconds < 60) {
    return 'just now';
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${diffInMinutes} minute${diffInMinutes !== 1 ? 's' : ''} ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${diffInHours} hour${diffInHours !== 1 ? 's' : ''} ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${diffInDays} day${diffInDays !== 1 ? 's' : ''} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  if (diffInMonths < 12) {
    return `${diffInMonths} month${diffInMonths !== 1 ? 's' : ''} ago`;
  }

  const diffInYears = Math.floor(diffInMonths / 12);
  return `${diffInYears} year${diffInYears !== 1 ? 's' : ''} ago`;
};

/**
 * Format duration in milliseconds to human readable
 * @param {number} duration - Duration in milliseconds
 * @returns {string} - Formatted duration string
 */
export const formatDuration = (duration) => {
  if (!duration || isNaN(duration)) return '0s';

  const seconds = Math.floor(duration / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (days > 0) {
    return `${days}d ${hours % 24}h ${minutes % 60}m`;
  }
  if (hours > 0) {
    return `${hours}h ${minutes % 60}m ${seconds % 60}s`;
  }
  if (minutes > 0) {
    return `${minutes}m ${seconds % 60}s`;
  }

  return `${seconds}s`;
};

/**
 * Status Formatting
 */

/**
 * Format investigation status for display
 * @param {string} status - Investigation status
 * @returns {Object} - Formatted status with display text and color
 */
export const formatInvestigationStatus = (status) => {
  const statusMap = {
    pending: { text: 'Pending', color: 'text-gray-600', bg: 'bg-gray-100' },
    initializing: { text: 'Initializing', color: 'text-blue-600', bg: 'bg-blue-100' },
    running: { text: 'Running', color: 'text-green-600', bg: 'bg-green-100' },
    analyzing: { text: 'Analyzing', color: 'text-purple-600', bg: 'bg-purple-100' },
    consolidating: { text: 'Consolidating', color: 'text-amber-600', bg: 'bg-amber-100' },
    completed: { text: 'Completed', color: 'text-emerald-600', bg: 'bg-emerald-100' },
    failed: { text: 'Failed', color: 'text-red-600', bg: 'bg-red-100' },
    cancelled: { text: 'Cancelled', color: 'text-gray-600', bg: 'bg-gray-100' },
    timeout: { text: 'Timeout', color: 'text-red-600', bg: 'bg-red-100' }
  };

  return statusMap[status] || statusMap.pending;
};

/**
 * Format risk level for display
 * @param {string} riskLevel - Risk level
 * @returns {Object} - Formatted risk level with display text and color
 */
export const formatRiskLevel = (riskLevel) => {
  const riskMap = {
    very_low: { text: 'Very Low', color: 'text-green-600', bg: 'bg-green-100', icon: '🟢' },
    low: { text: 'Low', color: 'text-lime-600', bg: 'bg-lime-100', icon: '🟡' },
    medium: { text: 'Medium', color: 'text-amber-600', bg: 'bg-amber-100', icon: '🟠' },
    high: { text: 'High', color: 'text-red-600', bg: 'bg-red-100', icon: '🔴' },
    very_high: { text: 'Very High', color: 'text-red-700', bg: 'bg-red-200', icon: '🚨' },
    critical: { text: 'Critical', color: 'text-red-900', bg: 'bg-red-300', icon: '⚠️' }
  };

  return riskMap[riskLevel] || riskMap.very_low;
};

/**
 * Format confidence level for display
 * @param {number} confidence - Confidence percentage (0-100)
 * @returns {Object} - Formatted confidence with display text and color
 */
export const formatConfidence = (confidence) => {
  if (confidence >= 80) {
    return { text: 'Very High', color: 'text-green-600', bg: 'bg-green-100' };
  }
  if (confidence >= 60) {
    return { text: 'High', color: 'text-lime-600', bg: 'bg-lime-100' };
  }
  if (confidence >= 40) {
    return { text: 'Medium', color: 'text-amber-600', bg: 'bg-amber-100' };
  }
  if (confidence >= 20) {
    return { text: 'Low', color: 'text-orange-600', bg: 'bg-orange-100' };
  }

  return { text: 'Very Low', color: 'text-red-600', bg: 'bg-red-100' };
};

/**
 * Data Structure Formatting
 */

/**
 * Format JSON data for display
 * @param {Object} data - JSON data to format
 * @param {number} indent - Indentation spaces
 * @returns {string} - Formatted JSON string
 */
export const formatJSON = (data, indent = 2) => {
  try {
    return JSON.stringify(data, null, indent);
  } catch (error) {
    return 'Invalid JSON data';
  }
};

/**
 * Format file size in bytes to human readable
 * @param {number} bytes - File size in bytes
 * @returns {string} - Formatted file size
 */
export const formatFileSize = (bytes) => {
  if (!bytes || isNaN(bytes)) return '0 B';

  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));

  return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${sizes[i]}`;
};

/**
 * Format array to comma-separated string
 * @param {Array} array - Array to format
 * @param {string} separator - Separator character
 * @returns {string} - Formatted string
 */
export const formatArray = (array, separator = ', ') => {
  if (!Array.isArray(array)) return '';
  return array.join(separator);
};

/**
 * Text Formatting
 */

/**
 * Capitalize first letter of string
 * @param {string} str - String to capitalize
 * @returns {string} - Capitalized string
 */
export const capitalize = (str) => {
  if (!str || typeof str !== 'string') return '';
  return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
};

/**
 * Convert camelCase to Title Case
 * @param {string} str - CamelCase string
 * @returns {string} - Title Case string
 */
export const camelToTitle = (str) => {
  if (!str || typeof str !== 'string') return '';

  return str
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (char) => char.toUpperCase())
    .trim();
};

/**
 * Convert snake_case to Title Case
 * @param {string} str - Snake_case string
 * @returns {string} - Title Case string
 */
export const snakeToTitle = (str) => {
  if (!str || typeof str !== 'string') return '';

  return str
    .split('_')
    .map(word => capitalize(word))
    .join(' ');
};

/**
 * Truncate text with ellipsis
 * @param {string} text - Text to truncate
 * @param {number} maxLength - Maximum length
 * @returns {string} - Truncated text
 */
export const truncateText = (text, maxLength = 50) => {
  if (!text || typeof text !== 'string') return '';

  if (text.length <= maxLength) return text;

  return text.slice(0, maxLength).trim() + '...';
};

/**
 * URL Formatting
 */

/**
 * Format blockchain explorer URL
 * @param {string} network - Blockchain network
 * @param {string} type - Type (address, tx, block)
 * @param {string} identifier - Address/hash/block number
 * @returns {string} - Explorer URL
 */
export const formatExplorerURL = (network, type, identifier) => {
  const explorers = {
    ethereum: 'https://etherscan.io',
    polygon: 'https://polygonscan.com',
    bsc: 'https://bscscan.com',
    arbitrum: 'https://arbiscan.io',
    optimism: 'https://optimistic.etherscan.io',
    avalanche: 'https://snowtrace.io',
    fantom: 'https://ftmscan.com',
    bitcoin: 'https://blockstream.info/bitcoin',
    solana: 'https://explorer.solana.com'
  };

  const baseURL = explorers[network.toLowerCase()];
  if (!baseURL) return '';

  const typeMap = {
    address: 'address',
    tx: 'tx',
    block: 'block'
  };

  const path = typeMap[type] || 'address';

  if (network.toLowerCase() === 'bitcoin') {
    return `${baseURL}/${path}/${identifier}`;
  }

  if (network.toLowerCase() === 'solana') {
    return `${baseURL}/${path}/${identifier}`;
  }

  return `${baseURL}/${path}/${identifier}`;
};

/**
 * Composite Formatters
 */

/**
 * Format transaction summary
 * @param {Object} transaction - Transaction data
 * @returns {Object} - Formatted transaction summary
 */
export const formatTransactionSummary = (transaction) => {
  if (!transaction) return {};

  return {
    hash: formatTransactionHash(transaction.hash),
    from: formatWalletAddress(transaction.from),
    to: formatWalletAddress(transaction.to),
    value: formatCrypto(transaction.value, transaction.symbol),
    timestamp: formatDateTime(transaction.timestamp),
    timeAgo: formatTimeAgo(transaction.timestamp),
    explorerURL: formatExplorerURL(
      transaction.network,
      'tx',
      transaction.hash
    )
  };
};

/**
 * Format investigation summary
 * @param {Object} investigation - Investigation data
 * @returns {Object} - Formatted investigation summary
 */
export const formatInvestigationSummary = (investigation) => {
  if (!investigation) return {};

  const status = formatInvestigationStatus(investigation.status);
  const risk = formatRiskLevel(investigation.riskLevel);
  const confidence = formatConfidence(investigation.confidence);

  return {
    id: investigation.id,
    walletAddress: formatWalletAddress(investigation.walletAddress),
    status: status,
    risk: risk,
    confidence: confidence,
    duration: formatDuration(investigation.duration),
    createdAt: formatDateTime(investigation.createdAt),
    timeAgo: formatTimeAgo(investigation.createdAt),
    flaggedActivities: investigation.flaggedActivities?.length || 0,
    recommendations: investigation.recommendations?.length || 0
  };
};

export default {
  // Number formatting
  formatLargeNumber,
  formatCurrency,
  formatCrypto,
  formatPercentage,
  formatDecimalAsPercentage,

  // Address formatting
  formatWalletAddress,
  formatTransactionHash,

  // Date formatting
  formatDate,
  formatDateTime,
  formatTimeAgo,
  formatDuration,

  // Status formatting
  formatInvestigationStatus,
  formatRiskLevel,
  formatConfidence,

  // Data formatting
  formatJSON,
  formatFileSize,
  formatArray,

  // Text formatting
  capitalize,
  camelToTitle,
  snakeToTitle,
  truncateText,

  // URL formatting
  formatExplorerURL,

  // Composite formatters
  formatTransactionSummary,
  formatInvestigationSummary
};
