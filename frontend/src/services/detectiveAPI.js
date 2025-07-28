import axios from 'axios';

const BASE_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8001';

// Create axios instance for detective API
const detectiveAPI = axios.create({
  baseURL: BASE_URL,
  timeout: 180000, // 3 minutes for AI operations (production needs more time)
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
detectiveAPI.interceptors.request.use(
  (config) => {
    console.log(`🕵️ Detective API: ${config.method?.toUpperCase()} ${config.url}`);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
detectiveAPI.interceptors.response.use(
  (response) => {
    console.log(`✅ API Success: ${response.config.method?.toUpperCase()} ${response.config.url} - ${response.status}`);
    return response.data;
  },
  (error) => {
    let message = 'An unexpected error occurred';
    let errorCode = 'UNKNOWN_ERROR';

    if (error.code === 'ECONNABORTED') {
      message = 'Request timeout - Investigation is taking longer than expected. Please try again.';
      errorCode = 'TIMEOUT_ERROR';
    } else if (error.response) {
      // Server responded with error status
      message = error.response?.data?.detail ||
               error.response?.data?.message ||
               `Server error: ${error.response.status}`;
      errorCode = `HTTP_${error.response.status}`;
    } else if (error.request) {
      // Request was made but no response received
      message = 'Unable to connect to the detective squad. Please check your connection.';
      errorCode = 'CONNECTION_ERROR';
    }

    console.error(`🚨 Detective API Error [${errorCode}]:`, message);
    const apiError = new Error(message);
    apiError.code = errorCode;
    return Promise.reject(apiError);
  }
);

// Detective Squad API Functions
export const detectiveService = {
  // Get legendary squad status
  getSquadStatus: async () => {
    return detectiveAPI.get('/api/v1/squad/status');
  },

  // Launch full squad investigation
  launchInvestigation: async (walletAddress, options = {}) => {
    const {
      depth = 2,
      includeMetadata = true,
      budget_limit = 5.0,
      user_id = 'frontend_user'
    } = options;

    // Use demo endpoint for fast results in production
    return detectiveAPI.post('/api/v1/wallet/investigate/demo', {
      wallet_address: walletAddress
    });
  },

  // Individual detective analysis
  detectiveAnalysis: {
    poirot: async (walletAddress) => {
      return detectiveAPI.post('/api/agents/detective/poirot', {
        wallet_address: walletAddress
      });
    },

    marple: async (walletAddress) => {
      return detectiveAPI.post('/api/agents/detective/marple', {
        wallet_address: walletAddress
      });
    },

    spade: async (walletAddress) => {
      return detectiveAPI.post('/api/agents/detective/spade', {
        wallet_address: walletAddress
      });
    },

    marlowe: async (walletAddress) => {
      return detectiveAPI.post('/api/agents/detective/marlowe', {
        wallet_address: walletAddress
      });
    },

    dupin: async (walletAddress) => {
      return detectiveAPI.post('/api/agents/detective/dupin', {
        wallet_address: walletAddress
      });
    },

    shadow: async (walletAddress) => {
      return detectiveAPI.post('/api/agents/detective/shadow', {
        wallet_address: walletAddress
      });
    },

    raven: async (walletAddress) => {
      return detectiveAPI.post('/api/agents/detective/raven', {
        wallet_address: walletAddress
      });
    }
  },

  // Get available detectives
  getAvailableDetectives: async () => {
    return detectiveAPI.get('/api/v1/detectives/available');
  },

  // Test real AI integration
  testRealAI: async () => {
    return detectiveAPI.get('/api/v1/test/ai');
  },

  // Health check
  healthCheck: async () => {
    return detectiveAPI.get('/api/v1/health');
  }
};

// AI Cost Management API
export const costService = {
  // Get cost dashboard data
  getDashboard: async () => {
    return detectiveAPI.get('/api/ai-costs/dashboard');
  },

  // Get user usage
  getUserUsage: async (userId = 'frontend_user') => {
    return detectiveAPI.get(`/api/ai-costs/usage/${userId}`);
  },

  // Update user limits
  updateUserLimits: async (limits, userId = 'frontend_user') => {
    return detectiveAPI.post('/api/ai-costs/update-limits', {
      user_id: userId,
      ...limits
    });
  },

  // Get providers status
  getProvidersStatus: async () => {
    return detectiveAPI.get('/api/ai-costs/providers/status');
  },

  // Get cost history
  getCostHistory: async (userId = 'frontend_user', days = 7) => {
    return detectiveAPI.get(`/api/ai-costs/history/${userId}?days=${days}`);
  }
};

// System Health API
export const systemService = {
  // Backend health check
  healthCheck: async () => {
    return detectiveAPI.get('/api/health');
  },

  // Database health
  databaseHealth: async () => {
    return detectiveAPI.get('/api/health/database');
  }
};

export default detectiveAPI;
