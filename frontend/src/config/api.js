// API Configuration for Ghost Wallet Hunter
// Production URLs for Render deployment

export const API_CONFIG = {
  // Backend principal - FastAPI
  BACKEND_URL: 'https://ghost-wallet-hunter.onrender.com',
  
  // A2A Server - Agent-to-Agent communication
  A2A_URL: 'https://a2a-6woy.onrender.com',
  
  // JuliaOS Core - Detective system
  JULIAOS_URL: 'https://juliaos-core.onrender.com',
  
  // Endpoints
  ENDPOINTS: {
    INVESTIGATE: '/api/agents/legendary-squad/investigate',
    REAL_AI_INVESTIGATE: '/api/real-ai/investigate',
    HEALTH: '/api/health',
    A2A_INVESTIGATE: '/swarm/investigate',
    JULIA_HEALTH: '/health',
    JULIA_AGENTS: '/api/v1/agents',
    JULIA_INVESTIGATE: '/api/v1/investigate'
  }
};

// Helper functions
export const getBackendUrl = (endpoint = '') => {
  return `${API_CONFIG.BACKEND_URL}${endpoint}`;
};

export const getA2AUrl = (endpoint = '') => {
  return `${API_CONFIG.A2A_URL}${endpoint}`;
};

export const getJuliaUrl = (endpoint = '') => {
  return `${API_CONFIG.JULIAOS_URL}${endpoint}`;
};

// Main investigation endpoint
export const getInvestigateUrl = () => {
  return getBackendUrl(API_CONFIG.ENDPOINTS.INVESTIGATE);
};

export const getRealAIInvestigateUrl = () => {
  return getBackendUrl(API_CONFIG.ENDPOINTS.REAL_AI_INVESTIGATE);
};
