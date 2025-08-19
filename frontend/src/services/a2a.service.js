/**
 * DEPRECATED: a2a.service.js relates to the legacy multi-agent (Python A2A) layer.
 * Replaced by Julia multi-detective orchestration. Keep only for transitional reference.
 * Remove after confirming no imports remain.
 */

/**
 * Ghost Wallet Hunter - A2A Service
 * ==================================
 *
 * Agent-to-Agent protocol service for coordinating detective agents.
 * Handles swarm intelligence and multi-agent communication at port 9100.
 */

import { createApiService, withRetry, healthCheck } from './api.service.js';
import { ENDPOINTS } from '../config/endpoints.js';
import { AGENTS, AGENT_CAPABILITIES } from '../config/constants.js';
import { IS_DEVELOPMENT } from '../config/environment.js';

// Create A2A client
const a2aClient = createApiService.a2a();

/**
 * Agent Management Service
 */
export const agentManagementService = {
  /**
   * Get all available agents
   */
  async getAgents() {
    return withRetry(() => a2aClient.get(ENDPOINTS.A2A.AGENTS.LIST));
  },

  /**
   * Get specific agent information
   * @param {string} agentId - Agent ID (e.g., 'poirot', 'marple', 'spade')
   */
  async getAgent(agentId) {
    if (!AGENTS[agentId.toUpperCase()]) {
      throw new Error(`Unknown agent: ${agentId}`);
    }

    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.AGENTS.GET.replace(':id', agentId))
    );
  },

  /**
   * Get agent status
   * @param {string} agentId - Agent ID
   */
  async getAgentStatus(agentId) {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.AGENTS.STATUS.replace(':id', agentId))
    );
  },

  /**
   * Get agent capabilities
   * @param {string} agentId - Agent ID
   */
  getAgentCapabilities(agentId) {
    const agentKey = agentId.toUpperCase();
    return AGENT_CAPABILITIES[agentKey] || [];
  },

  /**
   * Get agents by capability
   * @param {string} capability - Required capability
   */
  getAgentsByCapability(capability) {
    return Object.entries(AGENT_CAPABILITIES)
      .filter(([_, capabilities]) => capabilities.includes(capability))
      .map(([agentKey, _]) => AGENTS[agentKey]);
  }
};

/**
 * Task Coordination Service
 */
export const taskCoordinationService = {
  /**
   * Create a new investigation task
   * @param {Object} task - Task definition
   * @param {string} task.wallet_address - Target wallet address
   * @param {string[]} task.agent_ids - Agents to assign
   * @param {Object} task.parameters - Task parameters
   */
  async createTask(task) {
    if (IS_DEVELOPMENT) {
      console.log('📋 Creating A2A Task:', task);
    }

    return withRetry(() =>
      a2aClient.post(ENDPOINTS.A2A.TASKS.CREATE, task)
    );
  },

  /**
   * Get task status
   * @param {string} taskId - Task ID
   */
  async getTaskStatus(taskId) {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.TASKS.STATUS.replace(':id', taskId))
    );
  },

  /**
   * Get task results
   * @param {string} taskId - Task ID
   */
  async getTaskResults(taskId) {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.TASKS.RESULTS.replace(':id', taskId))
    );
  },

  /**
   * Cancel a task
   * @param {string} taskId - Task ID
   */
  async cancelTask(taskId) {
    return withRetry(() =>
      a2aClient.post(ENDPOINTS.A2A.TASKS.CANCEL.replace(':id', taskId))
    );
  },

  /**
   * Get all tasks
   * @param {Object} filters - Query filters
   */
  async getTasks(filters = {}) {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.TASKS.LIST, { params: filters })
    );
  }
};

/**
 * Swarm Intelligence Service
 */
export const swarmService = {
  /**
   * Start swarm investigation
   * @param {Object} params - Swarm parameters
   * @param {string} params.wallet_address - Target wallet
   * @param {string[]} params.agent_types - Types of agents to use
   * @param {Object} params.coordination_strategy - How agents should coordinate
   */
  async startSwarmInvestigation(params) {
    if (IS_DEVELOPMENT) {
      console.log('🐝 Starting Swarm Investigation:', params);
    }

    return withRetry(() =>
      a2aClient.post(ENDPOINTS.A2A.SWARM.START, params)
    );
  },

  /**
   * Get swarm status
   * @param {string} swarmId - Swarm ID
   */
  async getSwarmStatus(swarmId) {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.SWARM.STATUS.replace(':id', swarmId))
    );
  },

  /**
   * Get swarm coordination data
   * @param {string} swarmId - Swarm ID
   */
  async getSwarmCoordination(swarmId) {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.SWARM.COORDINATION.replace(':id', swarmId))
    );
  },

  /**
   * Stop swarm investigation
   * @param {string} swarmId - Swarm ID
   */
  async stopSwarm(swarmId) {
    return withRetry(() =>
      a2aClient.post(ENDPOINTS.A2A.SWARM.STOP.replace(':id', swarmId))
    );
  }
};

/**
 * Communication Service
 */
export const communicationService = {
  /**
   * Send message between agents
   * @param {Object} message - Message data
   * @param {string} message.from_agent - Sender agent ID
   * @param {string} message.to_agent - Recipient agent ID
   * @param {Object} message.content - Message content
   */
  async sendMessage(message) {
    return withRetry(() =>
      a2aClient.post(ENDPOINTS.A2A.COMMUNICATION.SEND, message)
    );
  },

  /**
   * Broadcast message to all agents
   * @param {Object} message - Message data
   */
  async broadcastMessage(message) {
    return withRetry(() =>
      a2aClient.post(ENDPOINTS.A2A.COMMUNICATION.BROADCAST, message)
    );
  },

  /**
   * Get agent communication log
   * @param {string} agentId - Agent ID
   * @param {Object} filters - Query filters
   */
  async getAgentCommunications(agentId, filters = {}) {
    return withRetry(() =>
      a2aClient.get(
        ENDPOINTS.A2A.COMMUNICATION.AGENT_LOG.replace(':id', agentId),
        { params: filters }
      )
    );
  },

  /**
   * Get task communication log
   * @param {string} taskId - Task ID
   */
  async getTaskCommunications(taskId) {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.COMMUNICATION.TASK_LOG.replace(':id', taskId))
    );
  }
};

/**
 * Compliance Service
 */
export const complianceService = {
  /**
   * Get compliance report for investigation
   * @param {string} investigationId - Investigation ID
   */
  async getComplianceReport(investigationId) {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.COMPLIANCE.REPORT.replace(':id', investigationId))
    );
  },

  /**
   * Validate investigation compliance
   * @param {Object} investigation - Investigation data
   */
  async validateCompliance(investigation) {
    return withRetry(() =>
      a2aClient.post(ENDPOINTS.A2A.COMPLIANCE.VALIDATE, investigation)
    );
  },

  /**
   * Get compliance rules
   */
  async getComplianceRules() {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.COMPLIANCE.RULES)
    );
  }
};

/**
 * Protocol Management Service
 */
export const protocolService = {
  /**
   * Get protocol status
   */
  async getProtocolStatus() {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.PROTOCOL.STATUS)
    );
  },

  /**
   * Get protocol metrics
   */
  async getProtocolMetrics() {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.PROTOCOL.METRICS)
    );
  },

  /**
   * Update protocol configuration
   * @param {Object} config - Protocol configuration
   */
  async updateProtocolConfig(config) {
    return withRetry(() =>
      a2aClient.put(ENDPOINTS.A2A.PROTOCOL.CONFIG, config)
    );
  }
};

/**
 * Health Service
 */
export const a2aHealthService = {
  /**
   * Check A2A protocol health
   */
  async checkHealth() {
    return healthCheck(a2aClient, ENDPOINTS.A2A.HEALTH.CHECK);
  },

  /**
   * Get system status
   */
  async getSystemStatus() {
    return withRetry(() =>
      a2aClient.get(ENDPOINTS.A2A.HEALTH.STATUS)
    );
  }
};

// Export comprehensive A2A service
export const a2aService = {
  agents: agentManagementService,
  tasks: taskCoordinationService,
  swarm: swarmService,
  communication: communicationService,
  compliance: complianceService,
  protocol: protocolService,
  health: a2aHealthService
};

export default a2aService;
