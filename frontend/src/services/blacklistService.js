/**
 * Blacklist Service
 * Frontend service for wallet blacklist verification
 */

import detectiveAPI from './detectiveAPI';

export const blacklistService = {
  // Check single wallet against blacklist
  checkWallet: async (walletAddress) => {
    return detectiveAPI.get(`/api/v1/blacklist/check/${walletAddress}`);
  },

  // Check multiple wallets against blacklist
  checkMultipleWallets: async (walletAddresses) => {
    return detectiveAPI.post('/api/v1/blacklist/check-multiple', walletAddresses);
  },

  // Get blacklist statistics
  getStats: async () => {
    return detectiveAPI.get('/api/v1/blacklist/stats');
  },

  // Force update blacklist
  forceUpdate: async () => {
    return detectiveAPI.post('/api/v1/blacklist/update');
  },

  // Search blacklist
  searchBlacklist: async (query) => {
    return detectiveAPI.get(`/api/v1/blacklist/search/${query}`);
  }
};

export default blacklistService;
