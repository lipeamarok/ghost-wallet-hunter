/**
 * Ghost Wallet Hunter - Endpoints Configuration
 * =============================================
 *
 * Centralized mapping of all API endpoints across all services.
 * Organized by service for better maintainability.
 */

// JuliaOS Endpoints (Port 10000)
export const JULIA_ENDPOINTS = {
  // Core
  HEALTH: '/health',
  API_HEALTH: '/api/health',
  TEST_HELLO: '/api/v1/test/hello',

  // Agents & Investigation
  API_AGENTS: '/api/v1/agents',
  API_INVESTIGATE: '/api/v1/tools/investigate_wallet',
  API_INVESTIGATE_SINGLE: '/api/v1/tools/investigate_wallet',
  API_INVESTIGATION_STATUS: '/api/v1/investigation/:id/status',
  API_INVESTIGATION_RESULTS: '/api/v1/investigation/:id/results'
};

// WebSocket Endpoints
export const WEBSOCKET_ENDPOINTS = {
  // Real-time updates
  INVESTIGATION_UPDATES: '/ws/investigation',
  AGENT_STATUS: '/ws/agents/status',
  SYSTEM_HEALTH: '/ws/system/health'
};

// Helper functions to build URLs with parameters
export const buildEndpoint = (template, params = {}) => {
  let endpoint = template;
  Object.entries(params).forEach(([key, value]) => {
    endpoint = endpoint.replace(`{${key}}`, encodeURIComponent(value));
  });
  return endpoint;
};

// Commonly used endpoint builders
export const ENDPOINT_BUILDERS = {
  // (All legacy backend/A2A builders removed in Julia-only mode)
};

export const API_SHAPE_VERSION = 'v2';

// Combined endpoints export for convenience
export const ENDPOINTS = {
  JULIA: JULIA_ENDPOINTS,
  WEBSOCKET: WEBSOCKET_ENDPOINTS,
  SHAPE_VERSION: API_SHAPE_VERSION
};

export default {
  JULIA_ENDPOINTS,
  WEBSOCKET_ENDPOINTS,
  ENDPOINTS,
  buildEndpoint,
  ENDPOINT_BUILDERS,
  API_SHAPE_VERSION
};
