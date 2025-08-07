/**
 * Ghost Wallet Hunter - Services Index
 * ====================================
 *
 * Centralized export for all service modules.
 * Provides unified access to the entire service layer.
 */

// Import services for internal use
import apiService from './api.service.js';
import backendService from './backend.service.js';
import a2aService from './a2a.service.js';
import juliaService from './julia.service.js';
import investigationService from './investigation.service.js';
import webSocketService from './websocket.service.js';

// Export services
export { createApiService, withRetry, healthCheck } from './api.service.js';
export { apiService };
export { default as backendService } from './backend.service.js';
export { default as a2aService } from './a2a.service.js';
export { default as juliaService } from './julia.service.js';
export { default as investigationService } from './investigation.service.js';
export { default as webSocketService } from './websocket.service.js';

// Individual Service Exports for Granular Access
export {
  authService,
  investigationService as backendInvestigationService,
  analyticsService,
  reportService,
  blacklistService,
  configService,
  healthService,
  demoService
} from './backend.service.js';

export {
  agentManagementService,
  taskCoordinationService,
  swarmService,
  communicationService,
  complianceService,
  protocolService,
  a2aHealthService
} from './a2a.service.js';

export {
  coreAnalysisService,
  juliaAgentsService,
  computationService,
  juliaDataService,
  performanceService,
  juliaConfigService,
  juliaHealthService
} from './julia.service.js';

export {
  investigationWebSocketService,
  agentWebSocketService,
  juliaWebSocketService,
  systemWebSocketService
} from './websocket.service.js';

/**
 * Service Health Monitor
 * (Moved after imports to avoid reference issues)
 */
const createServiceHealthMonitor = () => ({
  /**
   * Check health of all services
   */
  async checkAllServices() {
    const healthChecks = await Promise.allSettled([
      backendService.health.checkHealth(),
      a2aService.health.checkHealth(),
      juliaService.health.checkHealth()
    ]);

    return {
      backend: healthChecks[0].status === 'fulfilled' ? healthChecks[0].value : { status: 'unhealthy', error: healthChecks[0].reason },
      a2a: healthChecks[1].status === 'fulfilled' ? healthChecks[1].value : { status: 'unhealthy', error: healthChecks[1].reason },
      julia: healthChecks[2].status === 'fulfilled' ? healthChecks[2].value : { status: 'unhealthy', error: healthChecks[2].reason },
      websockets: webSocketService.getConnectionStatuses()
    };
  },

  /**
   * Get service availability summary
   */
  async getServiceAvailability() {
    const health = await this.checkAllServices();

    return {
      backend: health.backend.status === 'healthy',
      a2a: health.a2a.status === 'healthy',
      julia: health.julia.status === 'healthy',
      websockets: Object.values(health.websockets).some(ws => ws.status === 'connected'),
      overall: health.backend.status === 'healthy' &&
               health.a2a.status === 'healthy' &&
               health.julia.status === 'healthy'
    };
  }
});

export const serviceHealthMonitor = createServiceHealthMonitor();

/**
 * Unified Service Interface
 * Provides a single entry point for common operations
 */
const createGhostWalletHunter = () => ({
  // Investigation workflows
  async investigate(walletAddress, options = {}) {
    return investigationService.startInvestigation({
      walletAddress,
      ...options
    });
  },

  async getInvestigationStatus(investigationId) {
    return investigationService.getStatus(investigationId);
  },

  async getInvestigationResults(investigationId) {
    return investigationService.getResults(investigationId);
  },

  // Service management
  services: {
    backend: backendService,
    a2a: a2aService,
    julia: juliaService,
    investigation: investigationService,
    websocket: webSocketService
  },

  // Health monitoring
  health: serviceHealthMonitor,

  // Quick actions
  async quickAnalysis(walletAddress) {
    return juliaService.analysis.analyzeWallet(walletAddress, {
      quick: true,
      timeout: 30000
    });
  },

  async getRiskScore(walletAddress) {
    const analysis = await backendService.analytics.getRiskAssessment(walletAddress);
    return analysis.risk_score || 0;
  },

  async checkBlacklist(walletAddress) {
    return backendService.blacklist.checkAddress(walletAddress);
  }
});

export const ghostWalletHunter = createGhostWalletHunter();

// Default export for convenience
export default {
  api: apiService,
  backend: backendService,
  a2a: a2aService,
  julia: juliaService,
  investigation: investigationService,
  websocket: webSocketService,
  health: serviceHealthMonitor,
  hunter: ghostWalletHunter
};
