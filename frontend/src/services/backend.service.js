/**
 * DEPRECATED: This backend.service.js file refers to the old Python FastAPI backend.
 * The project migrated to a direct Julia-only pipeline. Keep temporarily only for reference.
 * Safe to delete once no residual imports remain.
 */

/**
 * Ghost Wallet Hunter - Backend Service
 * =====================================
 *
 * FastAPI integration layer with authentication, health monitoring, and investigation endpoints.
 * Handles communication with the Python backend at port 8001.
 */

import { createApiService, withRetry, healthCheck } from './api.service.js';
import { ENDPOINTS } from '../config/endpoints.js';
import { IS_DEVELOPMENT } from '../config/environment.js';

// Create backend client
const backendClient = createApiService.backend();

/**
 * Authentication Service
 */
export const authService = {
  /**
   * Test authentication endpoint
   */
  async testAuth() {
    return withRetry(() => backendClient.get(ENDPOINTS.BACKEND.AUTH.TEST));
  },

  /**
   * Get current user information
   */
  async getCurrentUser() {
    return withRetry(() => backendClient.get(ENDPOINTS.BACKEND.AUTH.USER));
  }
};

/**
 * Investigation Service
 */
export const investigationService = {
  /**
   * Start a new investigation
   * @param {Object} params - Investigation parameters
   * @param {string} params.wallet_address - Target wallet address
   * @param {string} params.analysis_type - Type of analysis to perform
   * @param {Object} params.options - Additional investigation options
   */
  async startInvestigation(params) {
    if (IS_DEVELOPMENT) {
      console.log('🔍 Starting Investigation:', params);
    }

    return withRetry(() =>
      backendClient.post(ENDPOINTS.BACKEND.INVESTIGATIONS.START, params)
    );
  },

  /**
   * Get investigation status
   * @param {string} investigationId - Investigation ID
   */
  async getInvestigationStatus(investigationId) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.INVESTIGATIONS.STATUS.replace(':id', investigationId))
    );
  },

  /**
   * Get investigation results
   * @param {string} investigationId - Investigation ID
   */
  async getInvestigationResults(investigationId) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.INVESTIGATIONS.RESULTS.replace(':id', investigationId))
    );
  },

  /**
   * Get all investigations
   */
  async getAllInvestigations() {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.INVESTIGATIONS.LIST)
    );
  },

  /**
   * Cancel an investigation
   * @param {string} investigationId - Investigation ID
   */
  async cancelInvestigation(investigationId) {
    return withRetry(() =>
      backendClient.post(ENDPOINTS.BACKEND.INVESTIGATIONS.CANCEL.replace(':id', investigationId))
    );
  },

  /**
   * Get investigation history
   * @param {Object} filters - Query filters
   */
  async getInvestigationHistory(filters = {}) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.INVESTIGATIONS.HISTORY, { params: filters })
    );
  }
};

/**
 * Analytics Service
 */
export const analyticsService = {
  /**
   * Get wallet analytics
   * @param {string} walletAddress - Wallet address to analyze
   */
  async getWalletAnalytics(walletAddress) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.ANALYTICS.WALLET.replace(':address', walletAddress))
    );
  },

  /**
   * Get transaction analytics
   * @param {string} transactionHash - Transaction hash to analyze
   */
  async getTransactionAnalytics(transactionHash) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.ANALYTICS.TRANSACTION.replace(':hash', transactionHash))
    );
  },

  /**
   * Get network analytics
   * @param {Object} params - Network analysis parameters
   */
  async getNetworkAnalytics(params = {}) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.ANALYTICS.NETWORK, { params })
    );
  },

  /**
   * Get risk assessment
   * @param {string} address - Address to assess
   */
  async getRiskAssessment(address) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.ANALYTICS.RISK.replace(':address', address))
    );
  }
};

/**
 * Report Service
 */
export const reportService = {
  /**
   * Generate investigation report
   * @param {string} investigationId - Investigation ID
   * @param {string} format - Report format (pdf, json, csv)
   */
  async generateReport(investigationId, format = 'json') {
    return withRetry(() =>
      backendClient.post(ENDPOINTS.BACKEND.REPORTS.GENERATE, {
        investigation_id: investigationId,
        format: format
      })
    );
  },

  /**
   * Download report
   * @param {string} reportId - Report ID
   */
  async downloadReport(reportId) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.REPORTS.DOWNLOAD.replace(':id', reportId), {
        responseType: 'blob'
      })
    );
  },

  /**
   * Get report status
   * @param {string} reportId - Report ID
   */
  async getReportStatus(reportId) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.REPORTS.STATUS.replace(':id', reportId))
    );
  }
};

/**
 * Blacklist Service
 */
export const blacklistService = {
  /**
   * Check if address is blacklisted
   * @param {string} address - Address to check
   */
  async checkAddress(address) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.BLACKLIST.CHECK.replace(':address', address))
    );
  },

  /**
   * Add address to blacklist
   * @param {Object} data - Blacklist data
   */
  async addAddress(data) {
    return withRetry(() =>
      backendClient.post(ENDPOINTS.BACKEND.BLACKLIST.ADD, data)
    );
  },

  /**
   * Remove address from blacklist
   * @param {string} address - Address to remove
   */
  async removeAddress(address) {
    return withRetry(() =>
      backendClient.delete(ENDPOINTS.BACKEND.BLACKLIST.REMOVE.replace(':address', address))
    );
  },

  /**
   * Get blacklist entries
   * @param {Object} filters - Query filters
   */
  async getBlacklist(filters = {}) {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.BLACKLIST.LIST, { params: filters })
    );
  }
};

/**
 * Configuration Service
 */
export const configService = {
  /**
   * Get system configuration
   */
  async getConfig() {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.CONFIG.GET)
    );
  },

  /**
   * Update system configuration
   * @param {Object} config - Configuration updates
   */
  async updateConfig(config) {
    return withRetry(() =>
      backendClient.put(ENDPOINTS.BACKEND.CONFIG.UPDATE, config)
    );
  }
};

/**
 * Health Service
 */
export const healthService = {
  /**
   * Check backend health
   */
  async checkHealth() {
    return healthCheck(backendClient, ENDPOINTS.BACKEND.HEALTH.CHECK);
  },

  /**
   * Get system status
   */
  async getSystemStatus() {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.HEALTH.STATUS)
    );
  },

  /**
   * Get performance metrics
   */
  async getMetrics() {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.HEALTH.METRICS)
    );
  }
};

/**
 * Demo Service (for development and testing)
 */
export const demoService = {
  /**
   * Run demo investigation
   */
  async runDemo() {
    return withRetry(() =>
      backendClient.post(ENDPOINTS.BACKEND.DEMO.RUN)
    );
  },

  /**
   * Get demo data
   */
  async getDemoData() {
    return withRetry(() =>
      backendClient.get(ENDPOINTS.BACKEND.DEMO.DATA)
    );
  }
};

// Export comprehensive backend service
export const backendService = {
  auth: authService,
  investigations: investigationService,
  analytics: analyticsService,
  reports: reportService,
  blacklist: blacklistService,
  config: configService,
  health: healthService,
  demo: demoService
};

export default backendService;
