/**
 * Ghost Wallet Hunter - Endpoints Configuration
 * =============================================
 *
 * Centralized mapping of all API endpoints across all services.
 * Organized by service for better maintainability.
 */

// Backend API Endpoints (Port 8001)
export const BACKEND_ENDPOINTS = {
  // Health & System
  ROOT: '/',
  HEALTH: '/api/health',
  HEALTH_DETAILED: '/api/health/detailed',
  VERSION: '/api/version',

  // Analysis & Investigation
  ANALYZE: '/api/analyze',
  ANALYZE_QUICK: '/api/analyze/quick',
  PATTERNS: '/api/patterns',

  // Agents & Detective Squad
  LEGENDARY_SQUAD_INVESTIGATE: '/api/agents/legendary-squad/investigate',
  DETECTIVE_ANALYZE: '/api/agents/detective/{detective_id}/analyze',
  AGENTS_AVAILABLE: '/api/agents/available',
  AGENTS_HEALTH: '/api/agents/health',

  // Frontend API (v1)
  WALLET_INVESTIGATE_TEST: '/api/v1/wallet/investigate/test',
  WALLET_INVESTIGATE: '/api/v1/wallet/investigate',
  SQUAD_STATUS: '/api/v1/squad/status',
  DETECTIVES: '/api/v1/detectives',
  DETECTIVES_AVAILABLE: '/api/v1/detectives/available',
  HEALTH_V1: '/api/v1/health',
  TEST_INTEGRATION: '/api/v1/test/integration',
  TEST_JULIAOS: '/api/v1/test/juliaos',
  WALLET_INVESTIGATE_DEMO: '/api/v1/wallet/investigate/demo',
  DEMO_HEALTH: '/api/v1/wallet/investigate/demo/health',

  // Investigation Management (mapped to existing endpoints)
  INVESTIGATIONS: {
    START: '/api/v1/wallet/investigate',
    STATUS: '/api/v1/investigation/:id/status',
    RESULTS: '/api/v1/investigation/:id/results',
    LIST: '/api/v1/investigations',
    CANCEL: '/api/v1/investigation/:id/cancel',
    HISTORY: '/api/v1/investigations/history'
  },

  // Real AI Investigation
  REAL_AI_INVESTIGATE: '/api/real-ai/investigate',
  REAL_AI_HEALTH: '/api/real-ai/health',
  REAL_AI_AGENT_STATUS: '/api/real-ai/agent-status',

  // AI Costs Management
  AI_COSTS_DASHBOARD: '/api/ai-costs/dashboard',
  AI_COSTS_UPDATE_LIMITS: '/api/ai-costs/update-limits',
  AI_COSTS_USAGE: '/api/ai-costs/usage/{user_id}',
  AI_COSTS_ALERTS_SETUP: '/api/ai-costs/alerts/setup',
  AI_COSTS_PROVIDERS_STATUS: '/api/ai-costs/providers/status',
  AI_COSTS_HEALTH: '/api/ai-costs/health',

  // Blacklist
  BLACKLIST_CHECK: '/api/v1/blacklist/check/{wallet_address}',
  BLACKLIST_CHECK_MULTIPLE: '/api/v1/blacklist/check-multiple',
  BLACKLIST_STATS: '/api/v1/blacklist/stats',
  BLACKLIST_UPDATE: '/api/v1/blacklist/update',
  BLACKLIST_SEARCH: '/api/v1/blacklist/search/{query}',
  BLACKLIST_RANDOM_EXAMPLE: '/api/v1/blacklist/random-example',

  // Performance Monitoring
  STATUS: '/api/status',
  JULIAOS_STATUS: '/api/juliaos/status',
  CACHE_STATS: '/api/cache/stats',
  CACHE_CLEANUP: '/api/cache/cleanup',
  ANALYSIS_TIMING: '/api/analysis/timing'
};

// A2A Server Endpoints (Port 9100)
export const A2A_ENDPOINTS = {
  // Core
  HEALTH: '/health',
  STATUS: '/status',

  // Swarm Intelligence
  SWARM_INVESTIGATE: '/swarm/investigate',
  SWARM_STATUS: '/swarm/status',
  SWARM_AGENTS: '/swarm/agents',

  // Individual Agents
  AGENTS: '/agents',
  AGENTS_COUNT: '/agents/count',
  AGENT_CARD: '/{agent_id}/card',
  AGENT_STATUS: '/{agent_id}/status',
  AGENT_INVESTIGATE: '/{agent_id}/investigate',
  AGENT_MESSAGE: '/{agent_id}/message',
  AGENT_ANALYZE: '/{agent_id}/analyze',

  // Julia Integration
  JULIA_HEALTH: '/julia/health',
  JULIA_CONNECTION: '/julia/connection',

  // Testing & Debug
  TEST_CONNECTIVITY: '/test/connectivity',
  DEBUG_AGENTS: '/debug/agents',

  // Minimal Server
  INVESTIGATE: '/investigate'
};

// JuliaOS Endpoints (Port 10000)
export const JULIA_ENDPOINTS = {
  // Core
  HEALTH: '/health',
  API_HEALTH: '/api/health',
  TEST_HELLO: '/api/v1/test/hello',

  // Agents & Investigation
  API_AGENTS: '/api/v1/agents',
  API_INVESTIGATE: '/api/v1/investigate',

  // Tools (if needed for direct access)
  TOOLS_PREFIX: '/api/v1/tools'
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
  // Detective analysis with specific detective
  detectiveAnalyze: (detectiveId) =>
    buildEndpoint(BACKEND_ENDPOINTS.DETECTIVE_ANALYZE, { detective_id: detectiveId }),

  // Blacklist check for specific wallet
  blacklistCheck: (walletAddress) =>
    buildEndpoint(BACKEND_ENDPOINTS.BLACKLIST_CHECK, { wallet_address: walletAddress }),

  // AI costs usage for specific user
  aiCostsUsage: (userId) =>
    buildEndpoint(BACKEND_ENDPOINTS.AI_COSTS_USAGE, { user_id: userId }),

  // A2A agent actions
  agentCard: (agentId) =>
    buildEndpoint(A2A_ENDPOINTS.AGENT_CARD, { agent_id: agentId }),

  agentStatus: (agentId) =>
    buildEndpoint(A2A_ENDPOINTS.AGENT_STATUS, { agent_id: agentId }),

  agentInvestigate: (agentId) =>
    buildEndpoint(A2A_ENDPOINTS.AGENT_INVESTIGATE, { agent_id: agentId }),

  agentMessage: (agentId) =>
    buildEndpoint(A2A_ENDPOINTS.AGENT_MESSAGE, { agent_id: agentId }),

  agentAnalyze: (agentId) =>
    buildEndpoint(A2A_ENDPOINTS.AGENT_ANALYZE, { agent_id: agentId })
};

// Combined endpoints export for convenience
export const ENDPOINTS = {
  BACKEND: BACKEND_ENDPOINTS,
  A2A: A2A_ENDPOINTS,
  JULIA: JULIA_ENDPOINTS,
  WEBSOCKET: WEBSOCKET_ENDPOINTS
};

export default {
  BACKEND_ENDPOINTS,
  A2A_ENDPOINTS,
  JULIA_ENDPOINTS,
  WEBSOCKET_ENDPOINTS,
  ENDPOINTS,
  buildEndpoint,
  ENDPOINT_BUILDERS
};
