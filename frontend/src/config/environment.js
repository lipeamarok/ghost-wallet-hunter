/**
 * Ghost Wallet Hunter - Environment Configuration
 * ===============================================
 *
 * Centralized environment-based configuration for all services.
 * Automatically switches between development and production URLs.
 */

// Get current environment mode
const ENV_MODE = import.meta.env.MODE || 'development';
const IS_DEVELOPMENT = ENV_MODE === 'development';
const IS_PRODUCTION = ENV_MODE === 'production';

// Environment-specific API URLs
const API_URLS = {
  development: {
    // Local development URLs
    JULIA: import.meta.env.VITE_JULIA_URL || import.meta.env.VITE_JULIAOS_URL || 'http://localhost:10000',
    WEBSOCKET: import.meta.env.VITE_WS_URL || 'ws://localhost:10000'
  },
  production: {
    // Production URLs (Render deployment)
    JULIA: import.meta.env.VITE_JULIA_URL || import.meta.env.VITE_JULIAOS_URL || 'https://juliaos-core.onrender.com',
    WEBSOCKET: import.meta.env.VITE_WS_URL || 'wss://juliaos-core.onrender.com'
  }
};

// Add feature flag for Julia-only investigation pipeline
const USE_JULIA_FRONTEND = import.meta.env.VITE_USE_JULIA_FRONTEND !== 'false';
const DISABLE_LEGACY_PROGRESS = import.meta.env.VITE_DISABLE_LEGACY_PROGRESS === 'true';

// App configuration
export const APP_CONFIG = {
  NAME: import.meta.env.VITE_APP_NAME || 'Ghost Wallet Hunter',
  VERSION: import.meta.env.VITE_APP_VERSION || '2.0.0',
  ENVIRONMENT: ENV_MODE,
  IS_DEVELOPMENT,
  IS_PRODUCTION,

  // Feature flags
  ENABLE_WEBSOCKETS: import.meta.env.VITE_ENABLE_WEBSOCKETS !== 'false', // Default enabled, can be disabled via env
  WEBSOCKET_AUTO_CONNECT: IS_PRODUCTION || import.meta.env.VITE_WS_AUTO_CONNECT === 'true', // Auto-connect in production, manual in dev
  USE_JULIA_FRONTEND,
  DISABLE_LEGACY_PROGRESS
};

// Get current environment URLs
export const getCurrentURLs = () => API_URLS[ENV_MODE];

// Direct access to current URLs
export const CURRENT_URLS = getCurrentURLs();

// Export environment flags and mode
export { IS_DEVELOPMENT, IS_PRODUCTION };
export const ENVIRONMENT = APP_CONFIG;
export { USE_JULIA_FRONTEND };
export { DISABLE_LEGACY_PROGRESS };

// Export individual URLs for convenience
export const {
  JULIA: JULIA_URL,
  WEBSOCKET: WEBSOCKET_URL
} = CURRENT_URLS;

// Debug info (only in development)
if (IS_DEVELOPMENT) {
  console.log('🔧 Environment Configuration:', {
    MODE: ENV_MODE,
    URLS: CURRENT_URLS,
    APP: APP_CONFIG
  });
}

export default {
  APP_CONFIG,
  CURRENT_URLS,
  getCurrentURLs,
  JULIA_URL,
  WEBSOCKET_URL,
  IS_DEVELOPMENT,
  IS_PRODUCTION
};
