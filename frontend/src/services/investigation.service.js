/**
 * Ghost Wallet Hunter - Investigation Service
 * ==========================================
 *
 * Unified investigation orchestrator that coordinates between Backend, A2A, and Julia services.
 * Provides high-level investigation workflows and multi-layer analysis coordination.
 */

import backendService from './backend.service.js';
import a2aService from './a2a.service.js';
import juliaService from './julia.service.js';
import { IS_DEVELOPMENT } from '../config/environment.js';
import { INVESTIGATION_TYPES, AGENTS, ANALYSIS_PRIORITIES } from '../config/constants.js';

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
   * @param {string[]} params.agentIds - Specific agents to use
   * @param {Object} params.options - Additional options
   */
  async startInvestigation(params) {
    const {
      walletAddress,
      investigationType = INVESTIGATION_TYPES.COMPREHENSIVE,
      agentIds = [],
      options = {}
    } = params;

    if (IS_DEVELOPMENT) {
      console.log('🔍 Starting Comprehensive Investigation:', {
        walletAddress,
        investigationType,
        agentIds,
        options
      });
    }

    try {
      // 1. Initialize investigation in backend
      const backendInvestigation = await backendService.investigations.startInvestigation({
        wallet_address: walletAddress,
        analysis_type: investigationType,
        options
      });

      // Extract investigation ID from response (handle multiple possible field names)
      const investigationId = backendInvestigation.investigation_id ||
                             backendInvestigation.investigationId ||
                             backendInvestigation.id;

      if (!investigationId) {
        throw new Error('No investigation ID returned from backend');
      }

      if (IS_DEVELOPMENT) {
        console.log('✅ Backend investigation started:', investigationId);
      }

      // 2. Create investigation state tracker
      const investigationState = {
        id: investigationId,
        walletAddress,
        type: investigationType,
        status: 'initializing',
        startTime: new Date(),
        backend: backendInvestigation,
        a2a: null,
        julia: null,
        results: {
          backend: backendInvestigation, // Store the full backend response
          a2a: null,
          julia: null,
          consolidated: null
        },
        progress: {
          backend: 0,
          a2a: 0,
          julia: 0,
          overall: 0
        }
      };

      this.activeInvestigations.set(investigationId, investigationState);

      // 3. Determine optimal agent allocation
      const selectedAgents = this.selectOptimalAgents(investigationType, agentIds);

      // 4. Start A2A coordination
      if (selectedAgents.length > 0) {
        try {
          const a2aTask = await a2aService.tasks.createTask({
            investigation_id: investigationId,
            wallet_address: walletAddress,
            agent_ids: selectedAgents,
            parameters: {
              investigation_type: investigationType,
              priority: ANALYSIS_PRIORITIES[investigationType] || 'medium',
              ...options
            }
          });

          investigationState.a2a = a2aTask;
          investigationState.status = 'agents_coordinating';
        } catch (a2aError) {
          console.warn('⚠️ A2A coordination failed, continuing with backend only:', a2aError.message);
        }
      }

      // 5. Start Julia core analysis
      try {
        const juliaAnalysis = await juliaService.analysis.analyzeWallet(walletAddress, {
          investigation_id: investigationId,
          analysis_type: investigationType,
          ...options
        });

        investigationState.julia = juliaAnalysis;
        investigationState.status = 'analyzing';
      } catch (juliaError) {
        console.warn('⚠️ Julia analysis failed, continuing without core analysis:', juliaError.message);
      }

      // 6. Update final status
      investigationState.status = 'running';
      this.activeInvestigations.set(investigationId, investigationState);

      if (IS_DEVELOPMENT) {
        console.log('✅ Investigation started successfully:', investigationId);
      }

      // Return the complete backend response plus additional data
      return {
        ...backendInvestigation, // Include all backend data
        investigationId, // Ensure we have the ID in the expected format
        investigation_id: investigationId, // Also provide it in snake_case format
        id: investigationId, // And in simple 'id' format
        status: investigationState.status,
        services: {
          backend: !!investigationState.backend,
          a2a: !!investigationState.a2a,
          julia: !!investigationState.julia
        },
        orchestratorData: {
          walletAddress,
          type: investigationType,
          startTime: investigationState.startTime
        }
      };

    } catch (error) {
      console.error('🚨 Investigation failed to start:', error);
      throw new Error(`Failed to start investigation: ${error.message}`);
    }
  }

  /**
   * Get comprehensive investigation status
   * @param {string} investigationId - Investigation ID
   */
  async getInvestigationStatus(investigationId) {
    if (!investigationId || investigationId === 'undefined') {
      throw new Error(`Invalid investigation ID: ${investigationId}`);
    }

    const investigation = this.activeInvestigations.get(investigationId);

    if (!investigation) {
      throw new Error(`Investigation not found: ${investigationId}`);
    }

    try {
      // Get status from all services
      const statusPromises = [];

      // Backend status
      statusPromises.push(
        backendService.investigations.getInvestigationStatus(investigationId)
          .catch(error => ({ error: error.message, service: 'backend' }))
      );

      // A2A status (if active)
      if (investigation.a2a) {
        statusPromises.push(
          a2aService.tasks.getTaskStatus(investigation.a2a.id)
            .catch(error => ({ error: error.message, service: 'a2a' }))
        );
      }

      // Julia status (if active)
      if (investigation.julia) {
        statusPromises.push(
          juliaService.analysis.getAnalysisStatus(investigation.julia.id)
            .catch(error => ({ error: error.message, service: 'julia' }))
        );
      }

      const statuses = await Promise.all(statusPromises);

      // Update investigation state
      investigation.progress = this.calculateProgress(statuses);
      investigation.status = this.determineOverallStatus(statuses);

      return {
        investigationId,
        walletAddress: investigation.walletAddress,
        type: investigation.type,
        status: investigation.status,
        progress: investigation.progress,
        startTime: investigation.startTime,
        services: {
          backend: statuses[0],
          a2a: investigation.a2a ? statuses[1] : null,
          julia: investigation.julia ? statuses[statuses.length - 1] : null
        }
      };

    } catch (error) {
      console.error('🚨 Failed to get investigation status:', error);
      throw error;
    }
  }

  /**
   * Get consolidated investigation results
   * @param {string} investigationId - Investigation ID
   */
  async getInvestigationResults(investigationId) {
    const investigation = this.activeInvestigations.get(investigationId);

    if (!investigation) {
      throw new Error(`Investigation not found: ${investigationId}`);
    }

    try {
      // Get results from all services
      const resultsPromises = [];

      // Backend results
      resultsPromises.push(
        backendService.investigations.getInvestigationResults(investigationId)
          .catch(error => ({ error: error.message, service: 'backend' }))
      );

      // A2A results (if active)
      if (investigation.a2a) {
        resultsPromises.push(
          a2aService.tasks.getTaskResults(investigation.a2a.id)
            .catch(error => ({ error: error.message, service: 'a2a' }))
        );
      }

      // Julia results (if active)
      if (investigation.julia) {
        resultsPromises.push(
          juliaService.analysis.getAnalysisResults(investigation.julia.id)
            .catch(error => ({ error: error.message, service: 'julia' }))
        );
      }

      const results = await Promise.all(resultsPromises);

      // Consolidate results
      const consolidatedResults = this.consolidateResults(results, investigation);

      // Update investigation state
      investigation.results = {
        backend: results[0],
        a2a: investigation.a2a ? results[1] : null,
        julia: investigation.julia ? results[results.length - 1] : null,
        consolidated: consolidatedResults
      };

      // Mark as completed if all services are done
      const status = await this.getInvestigationStatus(investigationId);
      if (status.status === 'completed') {
        this.moveToHistory(investigationId);
      }

      return consolidatedResults;

    } catch (error) {
      console.error('🚨 Failed to get investigation results:', error);
      throw error;
    }
  }

  /**
   * Cancel investigation across all services
   * @param {string} investigationId - Investigation ID
   */
  async cancelInvestigation(investigationId) {
    const investigation = this.activeInvestigations.get(investigationId);

    if (!investigation) {
      throw new Error(`Investigation not found: ${investigationId}`);
    }

    try {
      const cancellationPromises = [];

      // Cancel backend investigation
      cancellationPromises.push(
        backendService.investigations.cancelInvestigation(investigationId)
          .catch(error => console.warn('Backend cancellation failed:', error.message))
      );

      // Cancel A2A task (if active)
      if (investigation.a2a) {
        cancellationPromises.push(
          a2aService.tasks.cancelTask(investigation.a2a.id)
            .catch(error => console.warn('A2A cancellation failed:', error.message))
        );
      }

      // Cancel Julia analysis (if active)
      if (investigation.julia) {
        cancellationPromises.push(
          juliaService.agents.stopExecution(investigation.julia.id)
            .catch(error => console.warn('Julia cancellation failed:', error.message))
        );
      }

      await Promise.all(cancellationPromises);

      // Update state
      investigation.status = 'cancelled';
      this.moveToHistory(investigationId);

      if (IS_DEVELOPMENT) {
        console.log('🛑 Investigation cancelled:', investigationId);
      }

      return { investigationId, status: 'cancelled' };

    } catch (error) {
      console.error('🚨 Failed to cancel investigation:', error);
      throw error;
    }
  }

  /**
   * Select optimal agents based on investigation type
   * @private
   */
  selectOptimalAgents(investigationType, requestedAgents = []) {
    // If specific agents requested, validate and use them
    if (requestedAgents.length > 0) {
      return requestedAgents.filter(agentId => {
        const agentKey = agentId.toUpperCase();
        return AGENTS[agentKey] !== undefined;
      });
    }

    // Auto-select agents based on investigation type
    switch (investigationType) {
      case INVESTIGATION_TYPES.FRAUD_DETECTION:
        return ['poirot', 'spade']; // Methodical detection + Hardboiled investigation

      case INVESTIGATION_TYPES.MONEY_LAUNDERING:
        return ['marple', 'marlowee']; // Social patterns + LA street smarts

      case INVESTIGATION_TYPES.COMPLIANCE_CHECK:
        return ['spade']; // Includes compliance features

      case INVESTIGATION_TYPES.RISK_ASSESSMENT:
        return ['dupin', 'shadow']; // Analytical + Stealth operations

      case INVESTIGATION_TYPES.PATTERN_ANALYSIS:
        return ['raven', 'dupin']; // Predictive + Analytical

      case INVESTIGATION_TYPES.COMPREHENSIVE:
      default:
        return ['poirot', 'marple', 'spade']; // Core detective trio
    }
  }

  /**
   * Calculate overall progress from service statuses
   * @private
   */
  calculateProgress(statuses) {
    const progress = { backend: 0, a2a: 0, julia: 0, overall: 0 };

    statuses.forEach((status, index) => {
      if (status && !status.error) {
        const progressValue = status.progress || 0;
        switch (index) {
          case 0: progress.backend = progressValue; break;
          case 1: progress.a2a = progressValue; break;
          case 2: progress.julia = progressValue; break;
        }
      }
    });

    // Calculate weighted overall progress
    const weights = { backend: 0.4, a2a: 0.3, julia: 0.3 };
    progress.overall = Math.round(
      progress.backend * weights.backend +
      progress.a2a * weights.a2a +
      progress.julia * weights.julia
    );

    return progress;
  }

  /**
   * Determine overall status from service statuses
   * @private
   */
  determineOverallStatus(statuses) {
    const validStatuses = statuses.filter(s => s && !s.error);

    if (validStatuses.length === 0) return 'failed';
    if (validStatuses.some(s => s.status === 'failed')) return 'failed';
    if (validStatuses.every(s => s.status === 'completed')) return 'completed';
    if (validStatuses.some(s => s.status === 'running')) return 'running';

    return 'pending';
  }

  /**
   * Consolidate results from all services
   * @private
   */
  consolidateResults(results, investigation) {
    const consolidated = {
      investigationId: investigation.id,
      walletAddress: investigation.walletAddress,
      investigationType: investigation.type,
      timestamp: new Date(),
      summary: {
        riskScore: 0,
        confidence: 0,
        flaggedActivities: [],
        compliance: {},
        recommendations: []
      },
      detailedFindings: {
        backend: results[0],
        agents: investigation.a2a ? results[1] : null,
        coreAnalysis: investigation.julia ? results[results.length - 1] : null
      },
      metadata: {
        duration: Date.now() - investigation.startTime,
        servicesUsed: {
          backend: !!results[0] && !results[0].error,
          a2a: investigation.a2a && !!results[1] && !results[1].error,
          julia: investigation.julia && !!results[results.length - 1] && !results[results.length - 1].error
        }
      }
    };

    // Aggregate risk scores and findings
    this.aggregateRiskAnalysis(consolidated, results);

    return consolidated;
  }

  /**
   * Aggregate risk analysis from all sources
   * @private
   */
  aggregateRiskAnalysis(consolidated, results) {
    const riskScores = [];
    const allFlags = [];
    const allRecommendations = [];

    results.forEach(result => {
      if (result && !result.error) {
        if (result.risk_score) riskScores.push(result.risk_score);
        if (result.flagged_activities) allFlags.push(...result.flagged_activities);
        if (result.recommendations) allRecommendations.push(...result.recommendations);
      }
    });

    // Calculate weighted average risk score
    if (riskScores.length > 0) {
      consolidated.summary.riskScore = Math.round(
        riskScores.reduce((sum, score) => sum + score, 0) / riskScores.length
      );
    }

    // Deduplicate and prioritize flags
    consolidated.summary.flaggedActivities = this.deduplicateFlags(allFlags);
    consolidated.summary.recommendations = this.prioritizeRecommendations(allRecommendations);

    // Calculate confidence based on service agreement
    consolidated.summary.confidence = this.calculateConfidence(results);
  }

  /**
   * Move completed investigation to history
   * @private
   */
  moveToHistory(investigationId) {
    const investigation = this.activeInvestigations.get(investigationId);
    if (investigation) {
      investigation.endTime = new Date();
      this.investigationHistory.push(investigation);
      this.activeInvestigations.delete(investigationId);
    }
  }

  /**
   * Get active investigations
   */
  getActiveInvestigations() {
    return Array.from(this.activeInvestigations.values());
  }

  /**
   * Get investigation history
   */
  getInvestigationHistory() {
    return [...this.investigationHistory];
  }

  /**
   * Helper methods for result processing
   * @private
   */
  deduplicateFlags(flags) {
    const unique = new Map();
    flags.forEach(flag => {
      const key = `${flag.type}-${flag.description}`;
      if (!unique.has(key) || unique.get(key).severity < flag.severity) {
        unique.set(key, flag);
      }
    });
    return Array.from(unique.values());
  }

  prioritizeRecommendations(recommendations) {
    return recommendations
      .filter((rec, index, arr) =>
        arr.findIndex(r => r.action === rec.action) === index
      )
      .sort((a, b) => (b.priority || 0) - (a.priority || 0));
  }

  calculateConfidence(results) {
    const validResults = results.filter(r => r && !r.error);
    if (validResults.length === 0) return 0;

    const avgConfidence = validResults.reduce((sum, r) =>
      sum + (r.confidence || 50), 0) / validResults.length;

    return Math.round(avgConfidence);
  }
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
  async getStatus(investigationId) {
    return investigationOrchestrator.getInvestigationStatus(investigationId);
  },

  /**
   * Get investigation results
   */
  async getResults(investigationId) {
    return investigationOrchestrator.getInvestigationResults(investigationId);
  },

  /**
   * Cancel investigation
   */
  async cancel(investigationId) {
    return investigationOrchestrator.cancelInvestigation(investigationId);
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
  }
};

export default investigationService;
