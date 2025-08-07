/**
 * Ghost Wallet Hunter - Unified API Service
 * =========================================
 *
 * Centralized HTTP client with interceptors, error handling, and retry logic.
 * Base service used by all other service modules.
 */

import axios from 'axios';
import { CURRENT_URLS, IS_DEVELOPMENT } from '../config/environment.js';
import { API_CONSTANTS, ERROR_CONSTANTS } from '../config/constants.js';

// Create base axios instance
const createApiClient = (baseURL, options = {}) => {
  const client = axios.create({
    baseURL,
    timeout: options.timeout || API_CONSTANTS.TIMEOUTS.DEFAULT,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers
    },
    ...options
  });

  // Request interceptor
  client.interceptors.request.use(
    (config) => {
      if (IS_DEVELOPMENT) {
        console.log(`🔗 API Request: ${config.method?.toUpperCase()} ${config.baseURL}${config.url}`);
      }

      // Add timestamp to prevent caching
      if (config.method === 'get') {
        config.params = {
          ...config.params,
          _t: Date.now()
        };
      }

      return config;
    },
    (error) => {
      console.error('🚨 Request Error:', error);
      return Promise.reject(error);
    }
  );

  // Response interceptor
  client.interceptors.response.use(
    (response) => {
      if (IS_DEVELOPMENT) {
        console.log(`✅ API Success: ${response.config.method?.toUpperCase()} ${response.config.url} - ${response.status}`);
      }

      // Return response.data by default, but keep full response available
      return response.data;
    },
    (error) => {
      const apiError = handleApiError(error);
      return Promise.reject(apiError);
    }
  );

  return client;
};

// Error handler
const handleApiError = (error) => {
  let message = 'An unexpected error occurred';
  let errorCode = ERROR_CONSTANTS.CODES.SERVICE_UNAVAILABLE;
  let statusCode = null;

  if (error.code === 'ECONNABORTED') {
    message = 'Request timeout - Operation is taking longer than expected. Please try again.';
    errorCode = ERROR_CONSTANTS.TYPES.TIMEOUT;
  } else if (error.response) {
    // Server responded with error status
    statusCode = error.response.status;
    message = error.response?.data?.detail ||
             error.response?.data?.message ||
             error.response?.data?.error ||
             `Server error: ${error.response.status}`;

    // Map status codes to error types
    switch (statusCode) {
      case API_CONSTANTS.STATUS_CODES.BAD_REQUEST:
        errorCode = ERROR_CONSTANTS.TYPES.VALIDATION;
        break;
      case API_CONSTANTS.STATUS_CODES.UNAUTHORIZED:
        errorCode = ERROR_CONSTANTS.TYPES.AUTHENTICATION;
        break;
      case API_CONSTANTS.STATUS_CODES.FORBIDDEN:
        errorCode = ERROR_CONSTANTS.TYPES.AUTHORIZATION;
        break;
      case API_CONSTANTS.STATUS_CODES.NOT_FOUND:
        errorCode = ERROR_CONSTANTS.TYPES.NOT_FOUND;
        break;
      case API_CONSTANTS.STATUS_CODES.TIMEOUT:
        errorCode = ERROR_CONSTANTS.TYPES.TIMEOUT;
        break;
      case API_CONSTANTS.STATUS_CODES.INTERNAL_ERROR:
      case API_CONSTANTS.STATUS_CODES.BAD_GATEWAY:
      case API_CONSTANTS.STATUS_CODES.SERVICE_UNAVAILABLE:
        errorCode = ERROR_CONSTANTS.TYPES.SERVER;
        break;
      default:
        errorCode = ERROR_CONSTANTS.TYPES.UNKNOWN;
    }
  } else if (error.request) {
    // Request was made but no response received
    message = 'Unable to connect to the service. Please check your connection.';
    errorCode = ERROR_CONSTANTS.TYPES.NETWORK;
  }

  console.error(`🚨 API Error [${errorCode}]:`, message);

  // Create enhanced error object
  const apiError = new Error(message);
  apiError.code = errorCode;
  apiError.statusCode = statusCode;
  apiError.originalError = error;

  return apiError;
};

// Retry wrapper for failed requests
const withRetry = async (fn, maxAttempts = API_CONSTANTS.RETRY.DEFAULT_ATTEMPTS) => {
  let lastError;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Don't retry on certain error types
      if (error.code === ERROR_CONSTANTS.TYPES.VALIDATION ||
          error.code === ERROR_CONSTANTS.TYPES.AUTHENTICATION ||
          error.code === ERROR_CONSTANTS.TYPES.AUTHORIZATION) {
        throw error;
      }

      // Don't retry on last attempt
      if (attempt === maxAttempts) {
        break;
      }

      // Calculate delay with exponential backoff
      const delay = API_CONSTANTS.RETRY.INITIAL_DELAY *
                   Math.pow(API_CONSTANTS.RETRY.BACKOFF_MULTIPLIER, attempt - 1);

      if (IS_DEVELOPMENT) {
        console.warn(`🔄 Retry attempt ${attempt}/${maxAttempts} after ${delay}ms delay`);
      }

      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw lastError;
};

// Health check utility
const healthCheck = async (client, endpoint = '/health') => {
  try {
    const response = await client.get(endpoint, { timeout: API_CONSTANTS.TIMEOUTS.HEALTH_CHECK });
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      response: response
    };
  } catch (error) {
    return {
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    };
  }
};

// Export API service factory
export const createApiService = {
  backend: (options = {}) => createApiClient(CURRENT_URLS.BACKEND, {
    timeout: API_CONSTANTS.TIMEOUTS.INVESTIGATION,
    ...options
  }),

  a2a: (options = {}) => createApiClient(CURRENT_URLS.A2A, {
    timeout: API_CONSTANTS.TIMEOUTS.INVESTIGATION,
    ...options
  }),

  julia: (options = {}) => createApiClient(CURRENT_URLS.JULIA, {
    timeout: API_CONSTANTS.TIMEOUTS.DEFAULT,
    ...options
  }),

  custom: (baseURL, options = {}) => createApiClient(baseURL, options)
};

// Export utilities
export { withRetry, healthCheck, handleApiError };

// Export default backend client for backward compatibility
export default createApiService.backend();
