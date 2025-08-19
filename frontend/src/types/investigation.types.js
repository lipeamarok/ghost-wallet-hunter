/**
 * Ghost Wallet Hunter - Investigation Types
 * =========================================
 *
 * Type definitions and interfaces for investigation workflows,
 * results, status tracking, and data structures.
 */

/**
 * Investigation Status Enum
 */
export const INVESTIGATION_STATUS = {
  PENDING: 'pending',
  INITIALIZING: 'initializing',
  RUNNING: 'running',
  ANALYZING: 'analyzing',
  CONSOLIDATING: 'consolidating',
  COMPLETED: 'completed',
  FAILED: 'failed',
  CANCELLED: 'cancelled',
  TIMEOUT: 'timeout'
};

/**
 * Investigation Types Enum
 */
export const INVESTIGATION_TYPES = {
  QUICK: 'quick',
  COMPREHENSIVE: 'comprehensive',
  DEEP: 'deep',
  FRAUD_DETECTION: 'fraud_detection',
  MONEY_LAUNDERING: 'money_laundering',
  COMPLIANCE_CHECK: 'compliance_check',
  RISK_ASSESSMENT: 'risk_assessment',
  PATTERN_ANALYSIS: 'pattern_analysis',
  CUSTOM: 'custom'
};

/**
 * Investigation Priority Levels
 */
export const INVESTIGATION_PRIORITY = {
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
  URGENT: 'urgent',
  CRITICAL: 'critical'
};

/**
 * Detective Agent Types
 */
export const DETECTIVE_AGENTS = {
  POIROT: 'poirot',
  MARPLE: 'marple',
  SHADOW: 'shadow',
  RAVEN: 'raven',
  MARLOWE: 'marlowe',
  DUPIN: 'dupin',
  SPADE: 'spade'
};

/**
 * Detective Agent Information
 */
export const DETECTIVE_INFO = {
  poirot: {
    name: 'Hercule Poirot',
    emoji: '🧐',
    methodology: 'methodical_analysis',
    description: 'Systematic and methodical investigation approach'
  },
  marple: {
    name: 'Miss Jane Marple',
    emoji: '👵',
    methodology: 'pattern_anomaly_detection',
    description: 'Pattern recognition and anomaly detection'
  },
  shadow: {
    name: 'The Shadow',
    emoji: '🕵️',
    methodology: 'stealth_investigation',
    description: 'Covert analysis and stealth investigation'
  },
  raven: {
    name: 'Detective Raven',
    emoji: '🐦‍⬛',
    methodology: 'dark_investigation',
    description: 'Dark web and cryptic pattern analysis'
  },
  marlowe: {
    name: 'Philip Marlowe',
    emoji: '🚬',
    methodology: 'deep_analysis_investigation',
    description: 'Deep dive analysis and corruption detection'
  },
  dupin: {
    name: 'Auguste Dupin',
    emoji: '🎓',
    methodology: 'analytical_reasoning_investigation',
    description: 'Logical reasoning and deductive analysis'
  },
  spade: {
    name: 'Sam Spade',
    emoji: '🍸',
    methodology: 'hard_boiled_investigation',
    description: 'Hard-boiled approach and threat evaluation'
  }
};

/**
 * Risk Level Classifications
 */
export const RISK_LEVELS = {
  VERY_LOW: 'Very Low',
  LOW: 'Low',
  MEDIUM: 'Medium',
  HIGH: 'High',
  VERY_HIGH: 'Very High',
  CRITICAL: 'Critical'
};

/**
 * Confidence Level Classifications
 */
export const CONFIDENCE_LEVELS = {
  VERY_LOW: 'Very Low',
  LOW: 'Low',
  MEDIUM: 'Medium',
  HIGH: 'High',
  VERY_HIGH: 'Very High'
};

/**
 * Risk Assessment Levels (updated for Julia backend compatibility)
 */
export const RISK_LEVELS_RAW = {
  VERY_LOW: 'very_low',
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
  VERY_HIGH: 'very_high',
  CRITICAL: 'critical'
};

/**
 * Confidence Levels (updated for Julia backend compatibility)
 */
export const CONFIDENCE_LEVELS_RAW = {
  VERY_LOW: 'very_low',    // 0-20%
  LOW: 'low',              // 21-40%
  MEDIUM: 'medium',        // 41-60%
  HIGH: 'high',            // 61-80%
  VERY_HIGH: 'very_high'   // 81-100%
};

/**
 * Flagged Activity Types
 */
export const FLAGGED_ACTIVITY_TYPES = {
  FRAUD: 'fraud',
  MONEY_LAUNDERING: 'money_laundering',
  SUSPICIOUS_PATTERN: 'suspicious_pattern',
  HIGH_RISK_TRANSACTION: 'high_risk_transaction',
  BLACKLISTED_ADDRESS: 'blacklisted_address',
  COMPLIANCE_VIOLATION: 'compliance_violation',
  UNUSUAL_BEHAVIOR: 'unusual_behavior',
  MIXER_USAGE: 'mixer_usage',
  RAPID_TRANSFERS: 'rapid_transfers',
  LARGE_AMOUNTS: 'large_amounts'
};

/**
 * Activity Severity Levels
 */
export const ACTIVITY_SEVERITY = {
  INFO: 1,
  LOW: 2,
  MEDIUM: 4,
  HIGH: 6,
  CRITICAL: 8,
  SEVERE: 10
};

/**
 * Investigation Request Structure
 * @typedef {Object} InvestigationRequest
 * @property {string} walletAddress - Target wallet address
 * @property {string} investigationType - Type of investigation
 * @property {string[]} agentIds - Specific agents to use
 * @property {string} priority - Investigation priority
 * @property {Object} options - Additional options
 * @property {Object} metadata - Request metadata
 */
export const createInvestigationRequest = ({
  walletAddress,
  investigationType = INVESTIGATION_TYPES.COMPREHENSIVE,
  agentIds = [],
  priority = INVESTIGATION_PRIORITY.MEDIUM,
  options = {},
  metadata = {}
}) => ({
  walletAddress: validateWalletAddress(walletAddress),
  investigationType,
  agentIds,
  priority,
  options: {
    timeout: 300000, // 5 minutes default
    includeMetadata: true,
    realTimeUpdates: true,
    ...options
  },
  metadata: {
    requestId: generateInvestigationId(),
    requestedAt: Date.now(),
    requestedBy: 'user',
    ...metadata
  }
});

/**
 * Investigation Response Structure
 * @typedef {Object} InvestigationResponse
 * @property {string} id - Investigation ID
 * @property {string} status - Current status
 * @property {Object} progress - Progress information
 * @property {Object} services - Service status
 * @property {string} startTime - Start timestamp
 * @property {number} estimatedDuration - Estimated duration in ms
 */
export const createInvestigationResponse = ({
  id,
  status = INVESTIGATION_STATUS.PENDING,
  progress = {},
  services = {},
  startTime = new Date().toISOString(),
  estimatedDuration = null
}) => ({
  id,
  status,
  progress: {
    overall: 0,
    backend: 0,
    a2a: 0,
    julia: 0,
    ...progress
  },
  services: {
    backend: false,
    a2a: false,
    julia: false,
    ...services
  },
  startTime,
  estimatedDuration,
  lastUpdate: new Date().toISOString()
});

/**
 * Investigation Results Structure
 * @typedef {Object} InvestigationResults
 * @property {string} investigationId - Investigation ID
 * @property {string} walletAddress - Analyzed wallet address
 * @property {Object} summary - Investigation summary
 * @property {Object} detailedFindings - Detailed findings by service
 * @property {Object} metadata - Investigation metadata
 */
export const createInvestigationResults = ({
  investigationId,
  walletAddress,
  investigationType,
  summary = {},
  detailedFindings = {},
  metadata = {}
}) => ({
  investigationId,
  walletAddress,
  investigationType,
  timestamp: new Date().toISOString(),
  summary: {
    riskScore: 0,
    riskLevel: RISK_LEVELS.VERY_LOW,
    confidence: 0,
    confidenceLevel: CONFIDENCE_LEVELS.VERY_LOW,
    flaggedActivities: [],
    recommendations: [],
    ...summary
  },
  detailedFindings: {
    backend: null,
    a2a: null,
    julia: null,
    ...detailedFindings
  },
  metadata: {
    duration: 0,
    servicesUsed: {},
    analysisDepth: 'standard',
    completedAt: new Date().toISOString(),
    ...metadata
  }
});

/**
 * Flagged Activity Structure
 * @typedef {Object} FlaggedActivity
 * @property {string} type - Activity type
 * @property {string} description - Activity description
 * @property {number} severity - Severity level (1-10)
 * @property {string} severityLevel - Human-readable severity
 * @property {Object} details - Additional details
 * @property {string} source - Detection source
 * @property {string} timestamp - Detection timestamp
 */
export const createFlaggedActivity = ({
  type,
  description,
  severity = ACTIVITY_SEVERITY.LOW,
  details = {},
  source = 'unknown',
  transactionHash = null,
  address = null
}) => ({
  id: generateActivityId(),
  type,
  description,
  severity,
  severityLevel: getSeverityLevel(severity),
  details: {
    transactionHash,
    address,
    ...details
  },
  source,
  timestamp: new Date().toISOString(),
  icon: getActivityIcon(type)
});

/**
 * Progress Tracking Structure
 * @typedef {Object} ProgressUpdate
 * @property {string} investigationId - Investigation ID
 * @property {string} service - Service name
 * @property {number} progress - Progress percentage
 * @property {string} status - Current status
 * @property {string} message - Progress message
 * @property {Object} metadata - Additional metadata
 */
export const createProgressUpdate = ({
  investigationId,
  service,
  progress = 0,
  status = 'running',
  message = '',
  metadata = {}
}) => ({
  investigationId,
  service,
  progress: Math.min(Math.max(progress, 0), 100), // Clamp between 0-100
  status,
  message,
  metadata,
  timestamp: new Date().toISOString()
});

/**
 * Agent Assignment Structure
 * @typedef {Object} AgentAssignment
 * @property {string} agentId - Agent identifier
 * @property {string} agentName - Agent name
 * @property {string} taskType - Assigned task type
 * @property {string} status - Assignment status
 * @property {Object} capabilities - Agent capabilities
 * @property {Object} performance - Performance metrics
 */
export const createAgentAssignment = ({
  agentId,
  agentName,
  taskType,
  status = 'assigned',
  capabilities = [],
  performance = {}
}) => ({
  agentId,
  agentName,
  taskType,
  status,
  capabilities,
  performance: {
    averageResponseTime: 0,
    successRate: 100,
    tasksCompleted: 0,
    ...performance
  },
  assignedAt: new Date().toISOString(),
  lastUpdate: new Date().toISOString()
});

/**
 * Recommendation Structure
 * @typedef {Object} Recommendation
 * @property {string} action - Recommended action
 * @property {string} reason - Reason for recommendation
 * @property {string} priority - Recommendation priority
 * @property {Object} details - Additional details
 */
export const createRecommendation = ({
  action,
  reason,
  priority = 'medium',
  category = 'general',
  details = {}
}) => ({
  id: generateRecommendationId(),
  action,
  reason,
  priority,
  category,
  details,
  timestamp: new Date().toISOString()
});

/**
 * Utility Functions
 */

// Generate unique investigation ID
const generateInvestigationId = () => {
  return `inv_${Date.now()}_${Math.random().toString(36).substr(2, 8)}`;
};

// Generate unique activity ID
const generateActivityId = () => {
  return `act_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
};

// Generate unique recommendation ID
const generateRecommendationId = () => {
  return `rec_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
};

// Validate wallet address format
const validateWalletAddress = (address) => {
  if (!address || typeof address !== 'string') {
    throw new Error('Wallet address must be a string');
  }

  // Basic Ethereum address validation
  if (!/^0x[a-fA-F0-9]{40}$/.test(address)) {
    throw new Error('Invalid wallet address format');
  }

  return address.toLowerCase();
};

// Get severity level from numeric value
const getSeverityLevel = (severity) => {
  if (severity >= 8) return 'Critical';
  if (severity >= 6) return 'High';
  if (severity >= 4) return 'Medium';
  if (severity >= 2) return 'Low';
  return 'Info';
};

// Get confidence level from percentage
export const getConfidenceLevel = (confidence) => {
  if (confidence >= 81) return CONFIDENCE_LEVELS.VERY_HIGH;
  if (confidence >= 61) return CONFIDENCE_LEVELS.HIGH;
  if (confidence >= 41) return CONFIDENCE_LEVELS.MEDIUM;
  if (confidence >= 21) return CONFIDENCE_LEVELS.LOW;
  return CONFIDENCE_LEVELS.VERY_LOW;
};

// Get risk level from score
export const getRiskLevel = (score) => {
  if (score >= 80) return RISK_LEVELS.CRITICAL;
  if (score >= 60) return RISK_LEVELS.VERY_HIGH;
  if (score >= 40) return RISK_LEVELS.HIGH;
  if (score >= 20) return RISK_LEVELS.MEDIUM;
  if (score >= 5) return RISK_LEVELS.LOW;
  return RISK_LEVELS.VERY_LOW;
};

// Get icon for activity type
const getActivityIcon = (type) => {
  const iconMap = {
    [FLAGGED_ACTIVITY_TYPES.FRAUD]: '🚨',
    [FLAGGED_ACTIVITY_TYPES.MONEY_LAUNDERING]: '💰',
    [FLAGGED_ACTIVITY_TYPES.SUSPICIOUS_PATTERN]: '🔍',
    [FLAGGED_ACTIVITY_TYPES.HIGH_RISK_TRANSACTION]: '⚠️',
    [FLAGGED_ACTIVITY_TYPES.BLACKLISTED_ADDRESS]: '🚫',
    [FLAGGED_ACTIVITY_TYPES.COMPLIANCE_VIOLATION]: '📋',
    [FLAGGED_ACTIVITY_TYPES.UNUSUAL_BEHAVIOR]: '👀',
    [FLAGGED_ACTIVITY_TYPES.MIXER_USAGE]: '🌀',
    [FLAGGED_ACTIVITY_TYPES.RAPID_TRANSFERS]: '⚡',
    [FLAGGED_ACTIVITY_TYPES.LARGE_AMOUNTS]: '💎'
  };
  return iconMap[type] || '❓';
};

/**
 * Type Validation Functions
 */
export const isValidInvestigationStatus = (status) => {
  return Object.values(INVESTIGATION_STATUS).includes(status);
};

export const isValidInvestigationType = (type) => {
  return Object.values(INVESTIGATION_TYPES).includes(type);
};

export const isValidRiskLevel = (level) => {
  return Object.values(RISK_LEVELS).includes(level);
};

export const isValidFlaggedActivityType = (type) => {
  return Object.values(FLAGGED_ACTIVITY_TYPES).includes(type);
};

// Validate investigation request
export const validateInvestigationRequest = (request) => {
  if (!request || typeof request !== 'object') {
    throw new Error('Investigation request must be an object');
  }

  if (!request.walletAddress) {
    throw new Error('Wallet address is required');
  }

  validateWalletAddress(request.walletAddress);

  if (request.investigationType && !isValidInvestigationType(request.investigationType)) {
    throw new Error('Invalid investigation type');
  }

  if (request.priority && !Object.values(INVESTIGATION_PRIORITY).includes(request.priority)) {
    throw new Error('Invalid investigation priority');
  }

  return true;
};

// Calculate overall progress from service progress
export const calculateOverallProgress = (serviceProgress) => {
  const weights = { backend: 0.4, a2a: 0.3, julia: 0.3 };
  const services = Object.keys(weights);

  let totalProgress = 0;
  let totalWeight = 0;

  services.forEach(service => {
    if (serviceProgress[service] !== undefined) {
      totalProgress += serviceProgress[service] * weights[service];
      totalWeight += weights[service];
    }
  });

  return totalWeight > 0 ? Math.round(totalProgress / totalWeight) : 0;
};

// Determine investigation completion status
export const isInvestigationComplete = (status) => {
  return [
    INVESTIGATION_STATUS.COMPLETED,
    INVESTIGATION_STATUS.FAILED,
    INVESTIGATION_STATUS.CANCELLED,
    INVESTIGATION_STATUS.TIMEOUT
  ].includes(status);
};

export default {
  INVESTIGATION_STATUS,
  INVESTIGATION_TYPES,
  INVESTIGATION_PRIORITY,
  RISK_LEVELS,
  CONFIDENCE_LEVELS,
  FLAGGED_ACTIVITY_TYPES,
  ACTIVITY_SEVERITY,
  createInvestigationRequest,
  createInvestigationResponse,
  createInvestigationResults,
  createFlaggedActivity,
  createProgressUpdate,
  createAgentAssignment,
  createRecommendation,
  getConfidenceLevel,
  getRiskLevel,
  isValidInvestigationStatus,
  isValidInvestigationType,
  isValidRiskLevel,
  isValidFlaggedActivityType,
  validateInvestigationRequest,
  calculateOverallProgress,
  isInvestigationComplete
};
