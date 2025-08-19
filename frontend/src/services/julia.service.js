/**
 * Ghost Wallet Hunter - Julia Service
 * ===================================
 *
 * Direct communication with JuliaOS core engine at port 10000.
 * High-performance blockchain analysis and detective agent coordination.
 */

import { createApiService, withRetry, healthCheck } from './api.service.js';
import { ENDPOINTS } from '../config/endpoints.js';
import { AGENTS, JULIA_CONFIG } from '../config/constants.js';
import { IS_DEVELOPMENT } from '../config/environment.js';

// Create Julia client with extended timeout for heavy computations
const juliaClient = createApiService.julia({
  timeout: JULIA_CONFIG.DEFAULT_TIMEOUT
});

/**
 * Core Analysis Service
 */
export const coreAnalysisService = {
  /**
   * Analyze wallet address using Julia core
   * @param {string} walletAddress - Wallet address to analyze
   * @param {Object} options - Analysis options
   */
  async analyzeWallet(walletAddress, options = {}) {
    if (IS_DEVELOPMENT) {
      console.log('🔬 Julia Core Analysis:', walletAddress, options);
    }

    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.ANALYSIS.WALLET, {
        address: walletAddress,
        ...options
      })
    );
  },

  /**
   * Analyze transaction patterns
   * @param {string[]} transactions - Transaction hashes
   * @param {Object} options - Analysis options
   */
  async analyzeTransactions(transactions, options = {}) {
    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.ANALYSIS.TRANSACTIONS, {
        transactions,
        ...options
      })
    );
  },

  /**
   * Perform network analysis
   * @param {Object} networkParams - Network analysis parameters
   */
  async analyzeNetwork(networkParams) {
    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.ANALYSIS.NETWORK, networkParams)
    , 2); // Reduced retries for expensive operations
  },

  /**
   * Run pattern detection algorithms
   * @param {Object} data - Data to analyze for patterns
   * @param {string[]} algorithms - Algorithms to use
   */
  async detectPatterns(data, algorithms = []) {
    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.ANALYSIS.PATTERNS, {
        data,
        algorithms
      })
    );
  },

  /**
   * Get analysis status
   * @param {string} analysisId - Analysis job ID
   */
  async getAnalysisStatus(analysisId) {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.ANALYSIS.STATUS.replace(':id', analysisId))
    );
  },

  /**
   * Get analysis results
   * @param {string} analysisId - Analysis job ID
   */
  async getAnalysisResults(analysisId) {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.ANALYSIS.RESULTS.replace(':id', analysisId))
    );
  },

  /**
   * Investigate wallet using Julia Frontend - REAL ENDPOINT ONLY
   * @param {string} walletAddress - Wallet address to investigate
   * @param {Object} options - Investigation options
   */
  async investigateWallet(walletAddress, options = {}) {
    if (IS_DEVELOPMENT) {
      console.log('🧠 Julia Investigation (REAL ENDPOINT ONLY):', walletAddress, options);
    }

    const path = ENDPOINTS.JULIA.API_INVESTIGATE;
    const synchronous = options.synchronous !== undefined ? options.synchronous : true;

    try {
      console.log('📡 Calling REAL Julia endpoint:', path);
      const result = await withRetry(() =>
        juliaClient.post(path, {
          wallet_address: walletAddress,
          agent_id: options.agent_id || 'poirot',
          investigation_type: options.investigation_type || 'comprehensive',
          priority: options.priority || 'normal',
          notify_frontend: options.notify_frontend || false,
          synchronous
        })
      );

      console.log('✅ REAL Julia response received:', result);
      return result;

    } catch (error) {
      console.error('🚨 REAL Julia endpoint failed:', error);
      console.error('🚨 Error details:', error.response?.data || error.message);
      throw error;
    }
  }
};

/**
 * Detective Agents Service (Direct Julia Communication)
 */
export const juliaAgentsService = {
  /**
   * Get all available Julia agents
   */
  async getAgents() {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.AGENTS.LIST)
    );
  },

  /**
   * Execute agent investigation
   * @param {string} agentId - Agent ID (poirot, marple, spade, etc.)
   * @param {Object} params - Investigation parameters
   */
  async executeAgent(agentId, params) {
    const agentKey = agentId.toUpperCase();
    if (!AGENTS[agentKey]) {
      throw new Error(`Unknown Julia agent: ${agentId}`);
    }

    if (IS_DEVELOPMENT) {
      console.log(`🕵️ Executing ${AGENTS[agentKey].name}:`, params);
    }

    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.AGENTS.EXECUTE.replace(':id', agentId), params)
    , 2); // Detective work can be intensive
  },

  /**
   * Get agent execution status
   * @param {string} executionId - Execution ID
   */
  async getExecutionStatus(executionId) {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.AGENTS.STATUS.replace(':id', executionId))
    );
  },

  /**
   * Get agent execution results
   * @param {string} executionId - Execution ID
   */
  async getExecutionResults(executionId) {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.AGENTS.RESULTS.replace(':id', executionId))
    );
  },

  /**
   * Stop agent execution
   * @param {string} executionId - Execution ID
   */
  async stopExecution(executionId) {
    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.AGENTS.STOP.replace(':id', executionId))
    );
  }
};

/**
 * Computation Service
 */
export const computationService = {
  /**
   * Submit computational job to Julia
   * @param {Object} job - Job definition
   * @param {string} job.algorithm - Algorithm to execute
   * @param {Object} job.data - Input data
   * @param {Object} job.parameters - Algorithm parameters
   */
  async submitJob(job) {
    if (IS_DEVELOPMENT) {
      console.log('⚙️ Submitting Julia Job:', job.algorithm);
    }

    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.COMPUTE.SUBMIT, job)
    );
  },

  /**
   * Get job status
   * @param {string} jobId - Job ID
   */
  async getJobStatus(jobId) {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.COMPUTE.STATUS.replace(':id', jobId))
    );
  },

  /**
   * Get job results
   * @param {string} jobId - Job ID
   */
  async getJobResults(jobId) {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.COMPUTE.RESULTS.replace(':id', jobId))
    );
  },

  /**
   * Cancel job
   * @param {string} jobId - Job ID
   */
  async cancelJob(jobId) {
    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.COMPUTE.CANCEL.replace(':id', jobId))
    );
  },

  /**
   * Get available algorithms
   */
  async getAlgorithms() {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.COMPUTE.ALGORITHMS)
    );
  }
};

/**
 * Data Service
 */
export const juliaDataService = {
  /**
   * Upload data to Julia environment
   * @param {Object} data - Data to upload
   * @param {string} dataType - Type of data (transactions, addresses, etc.)
   */
  async uploadData(data, dataType) {
    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.DATA.UPLOAD, {
        data,
        type: dataType
      })
    );
  },

  /**
   * Get data from Julia environment
   * @param {string} dataId - Data ID
   */
  async getData(dataId) {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.DATA.GET.replace(':id', dataId))
    );
  },

  /**
   * Process data with Julia functions
   * @param {string} dataId - Data ID
   * @param {string} processor - Processing function name
   * @param {Object} params - Processing parameters
   */
  async processData(dataId, processor, params = {}) {
    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.DATA.PROCESS, {
        data_id: dataId,
        processor,
        parameters: params
      })
    );
  },

  /**
   * Delete data from Julia environment
   * @param {string} dataId - Data ID
   */
  async deleteData(dataId) {
    return withRetry(() =>
      juliaClient.delete(ENDPOINTS.JULIA.DATA.DELETE.replace(':id', dataId))
    );
  }
};

/**
 * Performance Service
 */
export const performanceService = {
  /**
   * Get Julia performance metrics
   */
  async getMetrics() {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.PERFORMANCE.METRICS)
    );
  },

  /**
   * Get system resources usage
   */
  async getResources() {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.PERFORMANCE.RESOURCES)
    );
  },

  /**
   * Get execution statistics
   */
  async getExecutionStats() {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.PERFORMANCE.EXECUTION)
    );
  },

  /**
   * Benchmark system performance
   * @param {Object} benchmarkParams - Benchmark parameters
   */
  async runBenchmark(benchmarkParams = {}) {
    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.PERFORMANCE.BENCHMARK, benchmarkParams)
    , 1); // Benchmarks are expensive, don't retry
  }
};

/**
 * Configuration Service
 */
export const juliaConfigService = {
  /**
   * Get Julia system configuration
   */
  async getConfig() {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.CONFIG.GET)
    );
  },

  /**
   * Update Julia configuration
   * @param {Object} config - Configuration updates
   */
  async updateConfig(config) {
    return withRetry(() =>
      juliaClient.put(ENDPOINTS.JULIA.CONFIG.UPDATE, config)
    );
  },

  /**
   * Reset Julia environment
   */
  async resetEnvironment() {
    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.CONFIG.RESET)
    , 1); // Don't retry environment resets
  }
};

/**
 * Health Service
 */
export const juliaHealthService = {
  /**
   * Check Julia core health
   */
  async checkHealth() {
    return healthCheck(juliaClient, ENDPOINTS.JULIA.HEALTH.CHECK);
  },

  /**
   * Get system status
   */
  async getSystemStatus() {
    return withRetry(() =>
      juliaClient.get(ENDPOINTS.JULIA.HEALTH.STATUS)
    );
  },

  /**
   * Run system diagnostics
   */
  async runDiagnostics() {
    return withRetry(() =>
      juliaClient.post(ENDPOINTS.JULIA.HEALTH.DIAGNOSTICS)
    , 1); // Diagnostics are comprehensive, don't retry
  }
};

// Export comprehensive Julia service
export const juliaService = {
  analysis: coreAnalysisService,
  agents: juliaAgentsService,
  compute: computationService,
  data: juliaDataService,
  performance: performanceService,
  config: juliaConfigService,
  health: juliaHealthService,
  // Async investigation polling helpers (Passo 2 em andamento)
  async getInvestigationStatus(id) {
    return withRetry(() => juliaClient.get(ENDPOINTS.JULIA.API_INVESTIGATION_STATUS.replace(':id', id)));
  },
  async getInvestigationResults(id) {
    return withRetry(() => juliaClient.get(ENDPOINTS.JULIA.API_INVESTIGATION_RESULTS.replace(':id', id)));
  }
};

export default juliaService;
