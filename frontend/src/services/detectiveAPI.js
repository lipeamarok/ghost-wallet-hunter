import axios from 'axios';

const BASE_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8001';

// Create axios instance for detective API
const detectiveAPI = axios.create({
  baseURL: BASE_URL,
  timeout: 300000, // 5 minutes for real AI operations
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

    // Use real investigation endpoint for actual analysis
    return detectiveAPI.post('/api/v1/wallet/investigate', {
      wallet_address: walletAddress,
      depth,
      include_metadata: includeMetadata,
      budget_limit,
      user_id
    });
  },

  // Individual detective analysis
  detectiveAnalysis: {
    poirot: async (walletAddress, focusArea = 'patterns') => {
      return detectiveAPI.post('/api/agents/detective/poirot/analyze', {
        wallet_address: walletAddress,
        focus_area: focusArea
      });
    },

    marple: async (walletAddress, focusArea = 'social_networks') => {
      return detectiveAPI.post('/api/agents/detective/marple/analyze', {
        wallet_address: walletAddress,
        focus_area: focusArea
      });
    },

    spade: async (walletAddress, focusArea = 'transactions') => {
      return detectiveAPI.post('/api/agents/detective/spade/analyze', {
        wallet_address: walletAddress,
        focus_area: focusArea
      });
    },

    marlowe: async (walletAddress, focusArea = 'privacy') => {
      return detectiveAPI.post('/api/agents/detective/marlowe/analyze', {
        wallet_address: walletAddress,
        focus_area: focusArea
      });
    },

    dupin: async (walletAddress, focusArea = 'behavioral') => {
      return detectiveAPI.post('/api/agents/detective/dupin/analyze', {
        wallet_address: walletAddress,
        focus_area: focusArea
      });
    },

    shadow: async (walletAddress, focusArea = 'stealth') => {
      return detectiveAPI.post('/api/agents/detective/shadow/analyze', {
        wallet_address: walletAddress,
        focus_area: focusArea
      });
    },

    raven: async (walletAddress, focusArea = 'intelligence') => {
      return detectiveAPI.post('/api/agents/detective/raven/analyze', {
        wallet_address: walletAddress,
        focus_area: focusArea
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
  },

  // Test integration
  testIntegration: async () => {
    return detectiveAPI.get('/api/v1/test/integration');
  },

  // Test JuliaOS connection
  testJuliaOS: async () => {
    return detectiveAPI.get('/api/v1/test/juliaos');
  },

  // Demo investigation
  demoInvestigation: async (walletAddress) => {
    return detectiveAPI.post('/api/v1/wallet/investigate/demo', {
      wallet_address: walletAddress
    });
  },

  // Test investigation
  testInvestigation: async (walletAddress) => {
    return detectiveAPI.post('/api/v1/wallet/investigate/test', {
      wallet_address: walletAddress
    });
  }
};

// AI Cost Management API
export const costService = {
  // Get cost dashboard data
  getDashboard: async () => {
    return detectiveAPI.get('/api/v1/ai-costs/dashboard');
  },

  // Get user usage
  getUserUsage: async (userId = 'frontend_user') => {
    return detectiveAPI.get(`/api/v1/ai-costs/usage/${userId}`);
  },

  // Update user limits
  updateUserLimits: async (limits, userId = 'frontend_user') => {
    return detectiveAPI.post('/api/v1/ai-costs/update-limits', {
      user_id: userId,
      ...limits
    });
  },

  // Get providers status
  getProvidersStatus: async () => {
    return detectiveAPI.get('/api/v1/ai-costs/providers/status');
  },

  // Get cost history
  getCostHistory: async (userId = 'frontend_user', days = 7) => {
    return detectiveAPI.get(`/api/v1/ai-costs/history/${userId}?days=${days}`);
  }
};

// Legendary Squad Investigation API
export const legendarySquadService = {
  // Full squad investigation (the main investigation endpoint)
  investigate: async (walletAddress, investigationType = 'comprehensive') => {
    return detectiveAPI.post('/api/agents/legendary-squad/investigate', {
      wallet_address: walletAddress,
      investigation_type: investigationType
    });
  },

  // Squad status check
  getStatus: async () => {
    return detectiveAPI.get('/api/agents/legendary-squad/status');
  }
};

// System Health API
export const systemService = {
  // Backend health check
  healthCheck: async () => {
    return detectiveAPI.get('/api/health');
  },

  // Detailed health check
  detailedHealth: async () => {
    return detectiveAPI.get('/api/health/detailed');
  },

  // Version info
  getVersion: async () => {
    return detectiveAPI.get('/api/health/version');
  }
};

// Blacklist Verification API
export const blacklistService = {
  // Check single wallet
  checkWallet: async (walletAddress) => {
    return detectiveAPI.get(`/api/v1/blacklist/check/${walletAddress}`);
  },

  // Check multiple wallets
  checkMultiple: async (walletAddresses) => {
    return detectiveAPI.post('/api/v1/blacklist/check-multiple', {
      wallet_addresses: walletAddresses
    });
  },

  // Get blacklist stats
  getStats: async () => {
    return detectiveAPI.get('/api/v1/blacklist/stats');
  },

  // Update blacklist
  updateBlacklist: async () => {
    return detectiveAPI.post('/api/v1/blacklist/update');
  },

  // Search blacklist
  search: async (query) => {
    return detectiveAPI.get(`/api/v1/blacklist/search/${query}`);
  },

  // Get random example
  getRandomExample: async () => {
    return detectiveAPI.get('/api/v1/blacklist/random-example');
  }
};

// Performance Monitoring API
export const performanceService = {
  // Overall system performance
  getStatus: async () => {
    return detectiveAPI.get('/api/performance/status');
  },

  // JuliaOS status
  getJuliaOSStatus: async () => {
    return detectiveAPI.get('/api/performance/juliaos/status');
  },

  // Cache stats
  getCacheStats: async () => {
    return detectiveAPI.get('/api/performance/cache/stats');
  },

  // Cache cleanup
  cleanupCache: async () => {
    return detectiveAPI.post('/api/performance/cache/cleanup');
  },

  // Analysis timing
  getAnalysisTiming: async () => {
    return detectiveAPI.get('/api/performance/analysis/timing');
  }
};

// Analysis API
export const analysisService = {
  // Main analysis endpoint
  analyze: async (walletAddress, depth = 'standard') => {
    return detectiveAPI.post('/api/analysis/analyze', {
      wallet_address: walletAddress,
      depth: depth
    });
  },

  // Quick analysis
  quickAnalyze: async (walletAddress) => {
    return detectiveAPI.get(`/api/analysis/analyze/quick/${walletAddress}`);
  },

  // Get patterns
  getPatterns: async () => {
    return detectiveAPI.get('/api/analysis/patterns');
  }
};

export default detectiveAPI;
