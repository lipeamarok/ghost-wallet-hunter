/**
 * Ghost Wallet Hunter - Validation Utilities
 * ==========================================
 *
 * Comprehensive validation functions for wallet addresses,
 * blockchain data, and application inputs.
 */

/**
 * Blockchain Network Constants
 */
export const BLOCKCHAIN_NETWORKS = {
  ETHEREUM: 'ethereum',
  BITCOIN: 'bitcoin',
  POLYGON: 'polygon',
  BSC: 'bsc',
  ARBITRUM: 'arbitrum',
  OPTIMISM: 'optimism',
  AVALANCHE: 'avalanche',
  FANTOM: 'fantom',
  SOLANA: 'solana',
  CARDANO: 'cardano'
};

/**
 * Address Format Patterns
 */
const ADDRESS_PATTERNS = {
  // Ethereum and EVM-compatible chains (40 hex chars + 0x prefix)
  ETHEREUM: /^0x[a-fA-F0-9]{40}$/,
  POLYGON: /^0x[a-fA-F0-9]{40}$/,
  BSC: /^0x[a-fA-F0-9]{40}$/,
  ARBITRUM: /^0x[a-fA-F0-9]{40}$/,
  OPTIMISM: /^0x[a-fA-F0-9]{40}$/,
  AVALANCHE: /^0x[a-fA-F0-9]{40}$/,
  FANTOM: /^0x[a-fA-F0-9]{40}$/,

  // Bitcoin addresses (Legacy, SegWit, Bech32)
  BITCOIN_LEGACY: /^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/,
  BITCOIN_SEGWIT: /^3[a-km-zA-HJ-NP-Z1-9]{25,34}$/,
  BITCOIN_BECH32: /^bc1[a-z0-9]{39,59}$/,

  // Solana addresses (Base58, 32-44 chars)
  SOLANA: /^[1-9A-HJ-NP-Za-km-z]{32,44}$/,

  // Cardano addresses (Bech32)
  CARDANO: /^addr1[a-z0-9]+$/
};

/**
 * Transaction Hash Patterns
 */
const TRANSACTION_PATTERNS = {
  // Ethereum and EVM-compatible (64 hex chars + 0x prefix)
  ETHEREUM: /^0x[a-fA-F0-9]{64}$/,

  // Bitcoin (64 hex chars, no prefix)
  BITCOIN: /^[a-fA-F0-9]{64}$/,

  // Solana (Base58, variable length)
  SOLANA: /^[1-9A-HJ-NP-Za-km-z]{64,88}$/
};

/**
 * Wallet Address Validation
 */

/**
 * Validate Ethereum address format
 * @param {string} address - Address to validate
 * @returns {boolean} - Validation result
 */
export const isValidEthereumAddress = (address) => {
  if (!address || typeof address !== 'string') return false;
  return ADDRESS_PATTERNS.ETHEREUM.test(address);
};

/**
 * Validate Bitcoin address format
 * @param {string} address - Address to validate
 * @returns {boolean} - Validation result
 */
export const isValidBitcoinAddress = (address) => {
  if (!address || typeof address !== 'string') return false;

  return (
    ADDRESS_PATTERNS.BITCOIN_LEGACY.test(address) ||
    ADDRESS_PATTERNS.BITCOIN_SEGWIT.test(address) ||
    ADDRESS_PATTERNS.BITCOIN_BECH32.test(address)
  );
};

/**
 * Validate Solana address format
 * @param {string} address - Address to validate
 * @returns {boolean} - Validation result
 */
export const isValidSolanaAddress = (address) => {
  if (!address || typeof address !== 'string') return false;
  return ADDRESS_PATTERNS.SOLANA.test(address);
};

/**
 * Validate Cardano address format
 * @param {string} address - Address to validate
 * @returns {boolean} - Validation result
 */
export const isValidCardanoAddress = (address) => {
  if (!address || typeof address !== 'string') return false;
  return ADDRESS_PATTERNS.CARDANO.test(address);
};

/**
 * Auto-detect blockchain network from address format
 * @param {string} address - Address to analyze
 * @returns {string|null} - Detected network or null
 */
export const detectAddressNetwork = (address) => {
  if (!address || typeof address !== 'string') return null;

  // Ethereum and EVM-compatible chains
  if (ADDRESS_PATTERNS.ETHEREUM.test(address)) {
    return BLOCKCHAIN_NETWORKS.ETHEREUM; // Default to Ethereum
  }

  // Bitcoin formats
  if (isValidBitcoinAddress(address)) {
    return BLOCKCHAIN_NETWORKS.BITCOIN;
  }

  // Solana
  if (ADDRESS_PATTERNS.SOLANA.test(address)) {
    return BLOCKCHAIN_NETWORKS.SOLANA;
  }

  // Cardano
  if (ADDRESS_PATTERNS.CARDANO.test(address)) {
    return BLOCKCHAIN_NETWORKS.CARDANO;
  }

  return null;
};

/**
 * Universal address validator
 * @param {string} address - Address to validate
 * @param {string} network - Specific network to validate against (optional)
 * @returns {Object} - Validation result with details
 */
export const validateWalletAddress = (address, network = null) => {
  const result = {
    isValid: false,
    network: null,
    format: null,
    error: null
  };

  if (!address || typeof address !== 'string') {
    result.error = 'Address must be a non-empty string';
    return result;
  }

  const trimmedAddress = address.trim();
  if (trimmedAddress.length === 0) {
    result.error = 'Address cannot be empty';
    return result;
  }

  // If specific network is provided, validate against it
  if (network) {
    switch (network.toLowerCase()) {
      case BLOCKCHAIN_NETWORKS.ETHEREUM:
      case BLOCKCHAIN_NETWORKS.POLYGON:
      case BLOCKCHAIN_NETWORKS.BSC:
      case BLOCKCHAIN_NETWORKS.ARBITRUM:
      case BLOCKCHAIN_NETWORKS.OPTIMISM:
      case BLOCKCHAIN_NETWORKS.AVALANCHE:
      case BLOCKCHAIN_NETWORKS.FANTOM:
        result.isValid = isValidEthereumAddress(trimmedAddress);
        result.network = network.toLowerCase();
        result.format = 'EVM';
        break;

      case BLOCKCHAIN_NETWORKS.BITCOIN:
        result.isValid = isValidBitcoinAddress(trimmedAddress);
        result.network = BLOCKCHAIN_NETWORKS.BITCOIN;
        result.format = 'Bitcoin';
        break;

      case BLOCKCHAIN_NETWORKS.SOLANA:
        result.isValid = isValidSolanaAddress(trimmedAddress);
        result.network = BLOCKCHAIN_NETWORKS.SOLANA;
        result.format = 'Solana';
        break;

      case BLOCKCHAIN_NETWORKS.CARDANO:
        result.isValid = isValidCardanoAddress(trimmedAddress);
        result.network = BLOCKCHAIN_NETWORKS.CARDANO;
        result.format = 'Cardano';
        break;

      default:
        result.error = `Unsupported network: ${network}`;
        return result;
    }

    if (!result.isValid) {
      result.error = `Invalid ${network} address format`;
    }

    return result;
  }

  // Auto-detect network
  const detectedNetwork = detectAddressNetwork(trimmedAddress);
  if (detectedNetwork) {
    result.isValid = true;
    result.network = detectedNetwork;

    // Set format based on network
    if ([BLOCKCHAIN_NETWORKS.ETHEREUM, BLOCKCHAIN_NETWORKS.POLYGON, BLOCKCHAIN_NETWORKS.BSC].includes(detectedNetwork)) {
      result.format = 'EVM';
    } else {
      result.format = detectedNetwork.charAt(0).toUpperCase() + detectedNetwork.slice(1);
    }
  } else {
    result.error = 'Unrecognized address format';
  }

  return result;
};

/**
 * Transaction Hash Validation
 */

/**
 * Validate transaction hash format
 * @param {string} hash - Transaction hash to validate
 * @param {string} network - Blockchain network (optional)
 * @returns {Object} - Validation result
 */
export const validateTransactionHash = (hash, network = null) => {
  const result = {
    isValid: false,
    network: null,
    error: null
  };

  if (!hash || typeof hash !== 'string') {
    result.error = 'Transaction hash must be a non-empty string';
    return result;
  }

  const trimmedHash = hash.trim();

  if (network) {
    switch (network.toLowerCase()) {
      case BLOCKCHAIN_NETWORKS.ETHEREUM:
      case BLOCKCHAIN_NETWORKS.POLYGON:
      case BLOCKCHAIN_NETWORKS.BSC:
        result.isValid = TRANSACTION_PATTERNS.ETHEREUM.test(trimmedHash);
        result.network = network.toLowerCase();
        break;

      case BLOCKCHAIN_NETWORKS.BITCOIN:
        result.isValid = TRANSACTION_PATTERNS.BITCOIN.test(trimmedHash);
        result.network = BLOCKCHAIN_NETWORKS.BITCOIN;
        break;

      case BLOCKCHAIN_NETWORKS.SOLANA:
        result.isValid = TRANSACTION_PATTERNS.SOLANA.test(trimmedHash);
        result.network = BLOCKCHAIN_NETWORKS.SOLANA;
        break;

      default:
        result.error = `Unsupported network: ${network}`;
        return result;
    }
  } else {
    // Auto-detect based on format
    if (TRANSACTION_PATTERNS.ETHEREUM.test(trimmedHash)) {
      result.isValid = true;
      result.network = 'EVM';
    } else if (TRANSACTION_PATTERNS.BITCOIN.test(trimmedHash)) {
      result.isValid = true;
      result.network = BLOCKCHAIN_NETWORKS.BITCOIN;
    } else if (TRANSACTION_PATTERNS.SOLANA.test(trimmedHash)) {
      result.isValid = true;
      result.network = BLOCKCHAIN_NETWORKS.SOLANA;
    } else {
      result.error = 'Unrecognized transaction hash format';
    }
  }

  if (!result.isValid && !result.error) {
    result.error = `Invalid transaction hash format for ${network || 'detected network'}`;
  }

  return result;
};

/**
 * Data Type Validation
 */

/**
 * Validate email format
 * @param {string} email - Email to validate
 * @returns {boolean} - Validation result
 */
export const isValidEmail = (email) => {
  if (!email || typeof email !== 'string') return false;
  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailPattern.test(email.trim());
};

/**
 * Validate URL format
 * @param {string} url - URL to validate
 * @returns {boolean} - Validation result
 */
export const isValidURL = (url) => {
  if (!url || typeof url !== 'string') return false;
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
};

/**
 * Validate numeric value with optional range
 * @param {any} value - Value to validate
 * @param {number} min - Minimum value (optional)
 * @param {number} max - Maximum value (optional)
 * @returns {boolean} - Validation result
 */
export const isValidNumber = (value, min = null, max = null) => {
  const num = Number(value);
  if (isNaN(num)) return false;
  if (min !== null && num < min) return false;
  if (max !== null && num > max) return false;
  return true;
};

/**
 * Validate positive integer
 * @param {any} value - Value to validate
 * @returns {boolean} - Validation result
 */
export const isValidPositiveInteger = (value) => {
  const num = Number(value);
  return Number.isInteger(num) && num > 0;
};

/**
 * Input Sanitization
 */

/**
 * Sanitize wallet address input
 * @param {string} address - Raw address input
 * @returns {string} - Sanitized address
 */
export const sanitizeWalletAddress = (address) => {
  if (!address || typeof address !== 'string') return '';

  return address
    .trim()
    .toLowerCase()
    .replace(/[^a-zA-Z0-9]/g, (char) => {
      // Keep specific characters for different address formats
      const allowedChars = ['x', 'X']; // For 0x prefix
      return allowedChars.includes(char) ? char : '';
    });
};

/**
 * Sanitize general text input
 * @param {string} input - Raw text input
 * @param {number} maxLength - Maximum length (optional)
 * @returns {string} - Sanitized text
 */
export const sanitizeTextInput = (input, maxLength = null) => {
  if (!input || typeof input !== 'string') return '';

  let sanitized = input.trim();

  // Remove potentially dangerous characters
  sanitized = sanitized.replace(/[<>'"&]/g, '');

  if (maxLength && sanitized.length > maxLength) {
    sanitized = sanitized.substring(0, maxLength);
  }

  return sanitized;
};

/**
 * Validation Error Messages
 */
export const VALIDATION_MESSAGES = {
  REQUIRED: 'This field is required',
  INVALID_EMAIL: 'Please enter a valid email address',
  INVALID_URL: 'Please enter a valid URL',
  INVALID_ADDRESS: 'Please enter a valid wallet address',
  INVALID_TRANSACTION: 'Please enter a valid transaction hash',
  INVALID_NUMBER: 'Please enter a valid number',
  OUT_OF_RANGE: 'Value is out of allowed range',
  TOO_LONG: 'Input is too long',
  TOO_SHORT: 'Input is too short'
};

/**
 * Comprehensive validation suite
 * @param {Object} data - Data to validate
 * @param {Object} rules - Validation rules
 * @returns {Object} - Validation results
 */
export const validateFormData = (data, rules) => {
  const errors = {};
  const sanitized = {};

  Object.keys(rules).forEach(field => {
    const rule = rules[field];
    const value = data[field];

    // Check required fields
    if (rule.required && (!value || value.toString().trim() === '')) {
      errors[field] = VALIDATION_MESSAGES.REQUIRED;
      return;
    }

    // Skip validation if field is empty and not required
    if (!value || value.toString().trim() === '') {
      sanitized[field] = '';
      return;
    }

    // Type-specific validation
    switch (rule.type) {
      case 'walletAddress':
        const addressValidation = validateWalletAddress(value, rule.network);
        if (!addressValidation.isValid) {
          errors[field] = addressValidation.error || VALIDATION_MESSAGES.INVALID_ADDRESS;
        } else {
          sanitized[field] = value.trim().toLowerCase();
        }
        break;

      case 'transactionHash':
        const hashValidation = validateTransactionHash(value, rule.network);
        if (!hashValidation.isValid) {
          errors[field] = hashValidation.error || VALIDATION_MESSAGES.INVALID_TRANSACTION;
        } else {
          sanitized[field] = value.trim();
        }
        break;

      case 'email':
        if (!isValidEmail(value)) {
          errors[field] = VALIDATION_MESSAGES.INVALID_EMAIL;
        } else {
          sanitized[field] = value.trim().toLowerCase();
        }
        break;

      case 'url':
        if (!isValidURL(value)) {
          errors[field] = VALIDATION_MESSAGES.INVALID_URL;
        } else {
          sanitized[field] = value.trim();
        }
        break;

      case 'number':
        if (!isValidNumber(value, rule.min, rule.max)) {
          errors[field] = rule.min !== undefined || rule.max !== undefined
            ? VALIDATION_MESSAGES.OUT_OF_RANGE
            : VALIDATION_MESSAGES.INVALID_NUMBER;
        } else {
          sanitized[field] = Number(value);
        }
        break;

      case 'text':
        sanitized[field] = sanitizeTextInput(value, rule.maxLength);
        if (rule.maxLength && value.length > rule.maxLength) {
          errors[field] = VALIDATION_MESSAGES.TOO_LONG;
        }
        if (rule.minLength && value.length < rule.minLength) {
          errors[field] = VALIDATION_MESSAGES.TOO_SHORT;
        }
        break;

      default:
        sanitized[field] = value;
    }
  });

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
    sanitized
  };
};

export default {
  BLOCKCHAIN_NETWORKS,
  isValidEthereumAddress,
  isValidBitcoinAddress,
  isValidSolanaAddress,
  isValidCardanoAddress,
  detectAddressNetwork,
  validateWalletAddress,
  validateTransactionHash,
  isValidEmail,
  isValidURL,
  isValidNumber,
  isValidPositiveInteger,
  sanitizeWalletAddress,
  sanitizeTextInput,
  VALIDATION_MESSAGES,
  validateFormData
};
