/**
 * Ghost Wallet Hunter - Investigation Service
 * ==========================================
 *
 * Unified investigation orchestrator that coordinates between Backend, A2A, and Julia services.
 * Provides high-level investigation workflows and multi-layer analysis coordination.
 */

import juliaService from './julia.service.js';
import { IS_DEVELOPMENT } from '../config/environment.js';
import { INVESTIGATION_TYPES } from '../config/constants.js';
import { USE_JULIA_FRONTEND } from '../config/environment.js';
import { mapJuliaResponse } from './dataMappers.js';

/**
 * Investigation Orchestration Service
 */
export class InvestigationOrchestrator {
  constructor() {
    this.activeInvestigations = new Map();
    this.investigationHistory = [];
  }

  /**
   * Start comprehensive investigation
   * @param {Object} params - Investigation parameters
   * @param {string} params.walletAddress - Target wallet address
   * @param {string} params.investigationType - Type of investigation
   * @param {Object} params.options - Additional options
   */
  async startInvestigation(params) {
    const {
      walletAddress,
      investigationType = INVESTIGATION_TYPES.COMPREHENSIVE,
      options = {}
    } = params;

    const synchronous = options.synchronous !== undefined ? options.synchronous : true;
    const investigation_type = options.investigation_type || 'comprehensive';

    if (IS_DEVELOPMENT) {
      console.log('🔍 Starting Investigation (Julia-only):', { walletAddress, investigationType });
    }

    const mapConsolidated = (rawEnvelope, ctx) => {
      if (!rawEnvelope) return null;
      // Unified envelope v2: results.raw, results.normalized
      const raw = rawEnvelope.raw || rawEnvelope;
      const preNormalized = rawEnvelope.normalized || rawEnvelope.results?.normalized || rawEnvelope.normalized;
      if (preNormalized && preNormalized.summary && preNormalized.detailedFindings) {
        return preNormalized; // Backend already provided normalized block
      }

      // Calculate average risk score from individual agents (for mock data)
      let riskRaw = raw.consensus_risk_score ?? raw.risk_score ?? raw.riskScore ?? raw.summary?.risk_score ?? 0;
      if (riskRaw === 0 && raw.individual_results) {
        const agentScores = Object.values(raw.individual_results)
          .map(agent => agent.analysis_results?.risk_score || 0)
          .filter(score => score > 0);
        if (agentScores.length > 0) {
          riskRaw = agentScores.reduce((sum, score) => sum + score, 0) / agentScores.length;
        }
      }

      const riskScore = riskRaw <= 1 ? Math.round(riskRaw * 10000) / 100 : riskRaw;
      const confRaw = raw.consensus_confidence ?? raw.confidence ?? raw.summary?.confidence ?? 0.7;
      const confidence = confRaw <= 1 ? Math.round(confRaw * 10000) / 100 : confRaw;
      const flagged = raw.flagged_activities || raw.flaggedActivities || raw.summary?.flaggedActivities || [];
      const recommendations = raw.recommendations || raw.summary?.recommendations || [];
      const durationMs = raw.duration_ms || raw.processing_time_ms || raw.duration || 0;
      const formattedDuration = formatDuration(durationMs);
      const detailedFindings = raw.detailed || raw.details || raw.detailedFindings || raw.findings || raw.individual_results || raw.agents || {};
      return {
        id: ctx.caseId,
        investigationId: ctx.caseId,
        walletAddress: raw.wallet_address || ctx.walletAddress,
        investigationType: ctx.investigationType,
        summary: {
          riskScore,
          confidence,
          flaggedActivities: flagged,
          recommendations,
          riskLevel: riskScore >= 80 ? 'High' : riskScore >= 50 ? 'Medium' : riskScore >= 20 ? 'Low' : 'Very Low',
          confidenceLevel: confidence >= 90 ? 'Very High' : confidence >= 70 ? 'High' : confidence >= 50 ? 'Medium' : 'Low'
        },
        detailedFindings,
        metadata: {
          walletAddress: raw.wallet_address || ctx.walletAddress,
            investigationType: ctx.investigationType,
            duration: durationMs,
            formattedDuration,
            completionTime: new Date().toLocaleString(),
            servicesUsed: { julia: true },
            agents: Object.keys(raw.individual_results || {})
        }
      };
    };

    // Fast path unified API
    if (USE_JULIA_FRONTEND) {
      console.log('🔍 Starting Julia investigation:', { walletAddress, investigationType });

      // Extract synchronous setting from nested options
      const synchronous = options.options?.synchronous !== undefined ?
        options.options.synchronous :
        (options.synchronous !== undefined ? options.synchronous : true);

      console.log('🔧 Investigation mode:', synchronous ? 'SYNCHRONOUS' : 'ASYNCHRONOUS');

      const juliaResponse = await juliaService.analysis.investigateWallet(walletAddress, {
        investigation_type: investigationType,
        priority: options.priority || 'normal',
        notify_frontend: !!options.notify_frontend,
        synchronous
      });

      console.log('📥 Julia response received, mapping data...');

      // Map Julia response using our mapper
      const mappedResults = mapJuliaResponse(juliaResponse);

      if (!mappedResults) {
        throw new Error('Failed to map Julia response to frontend format');
      }

      const caseId = juliaResponse.investigation_id || mappedResults.investigationId;
      const payload = {
        investigationId: caseId,
        id: caseId,
        shortId: caseId.slice(-8),
        status: 'completed',
        progress: { overall: 100, julia: 100 },
        services: { julia: true },
        results: mappedResults, // Use mapped results directly
        walletAddress,
        investigationType,
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
        version: "2.0.0"
      };

      this.activeInvestigations.set(caseId, payload);
      this.investigationHistory.push({
        id: caseId,
        status: 'completed',
        walletAddress,
        investigationType,
        completedAt: payload.completedAt,
        riskScore: mappedResults?.summary?.riskScore || 0
      });

      console.log('✅ Investigation completed, returning payload');
      return payload;
    }
    throw new Error('Julia frontend mode disabled but legacy pipeline removed. Enable VITE_USE_JULIA_FRONTEND.');
  }

  /**
   * Get comprehensive investigation status
   * @param {string} investigationId - Investigation ID
   */
  async getInvestigationStatus(investigationId) {
    const inv = this.activeInvestigations.get(investigationId);
    if (!inv) return { investigationId, status: 'completed', progress: { overall: 100 }, services: { julia: true } };
    return { investigationId, status: inv.status, progress: inv.progress || { overall: 100 }, services: { julia: true } };
  }

  /**
   * Get consolidated investigation results
   * @param {string} investigationId - Investigation ID
   */
  async getInvestigationResults(investigationId) {
    const record = this.activeInvestigations.get(investigationId);
    if (!record) {
      return null; // graceful null
    }

    // Use new data mappers to transform results
    const consolidated = record.results?.consolidated || record.results;
    if (consolidated && record.results?.raw) {
      // Apply Julia response mapping
      const mappedResults = mapJuliaResponse(record.results.raw);
      return {
        ...consolidated,
        detectives: mappedResults.detectives,
        metadata: {
          ...consolidated.metadata,
          ...mappedResults.metadata
        },
        rawResults: record.results.raw
      };
    }

    return consolidated;
  }

  /**
   * Cancel investigation across all services
   * @param {string} investigationId - Investigation ID
   */
  async cancelInvestigation() { throw new Error('Cancellation not supported in instantaneous mode'); }

  /**
   * Get active investigations
   */
  getActiveInvestigations() { return []; }

  /**
   * Get investigation history
   */
  getInvestigationHistory() { return this.investigationHistory; }
}

// Create singleton instance
const investigationOrchestrator = new InvestigationOrchestrator();

// Export high-level investigation API
export const investigationService = {
  /**
   * Start new investigation
   */
  async startInvestigation(params) {
    return investigationOrchestrator.startInvestigation(params);
  },

  /**
   * Get investigation status
   */
  async getStatus(id) {
    return investigationOrchestrator.getInvestigationStatus(id);
  },

  /**
   * Get investigation results
   */
  async getResults(id) {
    return investigationOrchestrator.getInvestigationResults(id);
  },

  /**
   * Cancel investigation
   */
  async cancel(id) {
    return investigationOrchestrator.cancelInvestigation(id);
  },

  /**
   * Get active investigations
   */
  getActive() {
    return investigationOrchestrator.getActiveInvestigations();
  },

  /**
   * Get investigation history
   */
  getHistory() {
    return investigationOrchestrator.getInvestigationHistory();
  },

  /**
   * Get investigation status (async mode polling)
   * @param {string} investigationId - Investigation ID
   */
  async getStatus(investigationId) {
    if (IS_DEVELOPMENT) {
      console.log('🔄 Polling investigation status:', investigationId);
    }
    return juliaService.getInvestigationStatus(investigationId);
  },

  /**
   * Get investigation results (async mode polling)
   * @param {string} investigationId - Investigation ID
   */
  async getResults(investigationId) {
    if (IS_DEVELOPMENT) {
      console.log('📊 Fetching investigation results:', investigationId);
    }

    if (!investigationId || investigationId === 'undefined') {
      throw new Error('Invalid investigation ID provided');
    }

    try {
      const rawResults = await juliaService.getInvestigationResults(investigationId);

      // Apply Julia response mapping to transform raw results
      if (rawResults) {
        const mappedResults = mapJuliaResponse(rawResults);
        console.log('🔍 DEBUG - Mapped Results Structure:', {
          hasSummary: !!mappedResults?.summary,
          hasDetectives: !!mappedResults?.detectives,
          keys: Object.keys(mappedResults || {})
        });

        return mappedResults;
      }

      return rawResults;

    } catch (error) {
      // If 404, this is expected in current synchronous architecture
      if (error.message?.includes('404') || error.response?.status === 404) {
        console.warn('📊 Investigation results endpoint not found (expected in synchronous mode)');
        throw new Error(`Investigation results not available. In synchronous mode, results should be passed via navigation state.`);
      }

      console.error('📊 Failed to fetch investigation results:', error);
      throw error;
    }
  }
};

export default investigationService;

// Helper: format duration ms to human readable
function formatDuration(ms) {
  if (!ms || ms < 1000) return `${Math.max(0, Math.round(ms/1000))}s`;
  const sec = Math.floor(ms / 1000);
  const m = Math.floor(sec / 60);
  const h = Math.floor(m / 60);
  const s = sec % 60;
  if (h > 0) return `${h}h ${m % 60}m ${s}s`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}
