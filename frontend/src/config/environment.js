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
    BACKEND: import.meta.env.VITE_BACKEND_URL || 'http://localhost:8001',
    A2A: import.meta.env.VITE_A2A_URL || 'http://localhost:9100',
    JULIA: import.meta.env.VITE_JULIA_URL || 'http://localhost:10000',
    WEBSOCKET: import.meta.env.VITE_WS_URL || 'ws://localhost:8001'
  },
  production: {
    // Production URLs (Render deployment)
    BACKEND: import.meta.env.VITE_BACKEND_URL || 'https://ghost-wallet-hunter.onrender.com',
    A2A: import.meta.env.VITE_A2A_URL || 'https://a2a-6woy.onrender.com',
    JULIA: import.meta.env.VITE_JULIA_URL || 'https://juliaos-core.onrender.com',
    WEBSOCKET: import.meta.env.VITE_WS_URL || 'wss://ghost-wallet-hunter.onrender.com'
  }
};

// App configuration
export const APP_CONFIG = {
  NAME: import.meta.env.VITE_APP_NAME || 'Ghost Wallet Hunter',
  VERSION: import.meta.env.VITE_APP_VERSION || '2.0.0',
  ENVIRONMENT: ENV_MODE,
  IS_DEVELOPMENT,
  IS_PRODUCTION,

  // Feature flags
  ENABLE_WEBSOCKETS: import.meta.env.VITE_ENABLE_WEBSOCKETS !== 'false', // Default enabled, can be disabled via env
  WEBSOCKET_AUTO_CONNECT: IS_PRODUCTION || import.meta.env.VITE_WS_AUTO_CONNECT === 'true' // Auto-connect in production, manual in dev
};

// Get current environment URLs
export const getCurrentURLs = () => API_URLS[ENV_MODE];

// Direct access to current URLs
export const CURRENT_URLS = getCurrentURLs();

// Export environment flags and mode
export { IS_DEVELOPMENT, IS_PRODUCTION };
export const ENVIRONMENT = APP_CONFIG;

// Export individual URLs for convenience
export const {
  BACKEND: BACKEND_URL,
  A2A: A2A_URL,
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
  BACKEND_URL,
  A2A_URL,
  JULIA_URL,
  WEBSOCKET_URL,
  IS_DEVELOPMENT,
  IS_PRODUCTION
};
