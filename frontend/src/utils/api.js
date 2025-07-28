import axios from 'axios';

const BASE_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8001';

// Create axios instance
const api = axios.create({
  baseURL: BASE_URL,
  timeout: 30000, // 30 seconds
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
api.interceptors.request.use(
  (config) => {
    console.log(`Making ${config.method?.toUpperCase()} request to ${config.url}`);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response) => {
    return response.data;
  },
  (error) => {
    const message = error.response?.data?.detail ||
                   error.response?.data?.message ||
                   error.message ||
                   'An unexpected error occurred';

    console.error('API Error:', message);
    return Promise.reject(new Error(message));
  }
);

// API Functions
export const healthCheck = async () => {
  return api.get('/');
};

export const analyzeWallet = async (walletAddress, options = {}) => {
  const {
    depth = 2,
    includeMetadata = true,
    useAI = true
  } = options;

  return api.post('/api/v1/analysis/wallet', {
    wallet_address: walletAddress,
    depth,
    include_metadata: includeMetadata,
    use_ai: useAI
  });
};

export const quickAnalysis = async (walletAddress) => {
  return api.post('/api/v1/analysis/quick', {
    wallet_address: walletAddress
  });
};

export const getAnalysisHistory = async () => {
  return api.get('/api/v1/analysis/history');
};

export default api;
