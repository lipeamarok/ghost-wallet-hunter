/**
 * Ghost Wallet Hunter - API Types
 * ===============================
 *
 * Type definitions and interfaces for API responses, requests,
 * and data structures used across all service layers.
 */

/**
 * HTTP Response Types
 */
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  ACCEPTED: 202,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL_SERVER_ERROR: 500,
  BAD_GATEWAY: 502,
  SERVICE_UNAVAILABLE: 503
};

/**
 * API Response Structure
 * @typedef {Object} ApiResponse
 * @property {boolean} success - Whether the request was successful
 * @property {*} data - Response data
 * @property {string} message - Response message
 * @property {number} timestamp - Response timestamp
 * @property {string} requestId - Unique request identifier
 */
export const createApiResponse = (success, data, message = null, requestId = null) => ({
  success,
  data,
  message,
  timestamp: Date.now(),
  requestId: requestId || generateRequestId()
});

/**
 * API Error Structure
 * @typedef {Object} ApiError
 * @property {string} code - Error code
 * @property {string} message - Error message
 * @property {string} type - Error type
 * @property {Object} details - Additional error details
 * @property {number} statusCode - HTTP status code
 * @property {string} service - Service that generated the error
 */
export const createApiError = (code, message, type = 'API_ERROR', details = {}, statusCode = 500, service = 'unknown') => ({
  code,
  message,
  type,
  details,
  statusCode,
  service,
  timestamp: Date.now()
});

/**
 * Backend API Types
 */
export const BACKEND_API_TYPES = {
  // Authentication
  AUTH_REQUEST: {
    username: 'string',
    password: 'string',
    rememberMe: 'boolean'
  },

  AUTH_RESPONSE: {
    token: 'string',
    user: 'object',
    permissions: 'array',
    expiresAt: 'number'
  },

  // Investigation Request
  INVESTIGATION_REQUEST: {
    walletAddress: 'string',
    investigationType: 'string',
    agents: 'array',
    options: 'object',
    priority: 'string'
  },

  // Investigation Response
  INVESTIGATION_RESPONSE: {
    id: 'string',
    walletAddress: 'string',
    status: 'string',
    progress: 'number',
    startTime: 'string',
    estimatedDuration: 'number',
    services: 'object'
  },

  // Analytics Request
  ANALYTICS_REQUEST: {
    address: 'string',
    timeRange: 'object',
    includeMetadata: 'boolean',
    depth: 'number'
  },

  // Analytics Response
  ANALYTICS_RESPONSE: {
    address: 'string',
    riskScore: 'number',
    confidence: 'number',
    transactionCount: 'number',
    totalValue: 'number',
    patterns: 'array',
    metadata: 'object'
  }
};

/**
 * A2A API Types
 */
export const A2A_API_TYPES = {
  // Agent Status
  AGENT_STATUS: {
    id: 'string',
    name: 'string',
    status: 'string',
    currentTask: 'string',
    capabilities: 'array',
    performance: 'object',
    lastHeartbeat: 'number'
  },

  // Task Creation
  TASK_REQUEST: {
    type: 'string',
    walletAddress: 'string',
    agentIds: 'array',
    parameters: 'object',
    priority: 'string',
    timeout: 'number'
  },

  // Task Response
  TASK_RESPONSE: {
    id: 'string',
    status: 'string',
    assignedAgents: 'array',
    progress: 'number',
    results: 'object',
    createdAt: 'string',
    updatedAt: 'string'
  },

  // Swarm Coordination
  SWARM_REQUEST: {
    walletAddress: 'string',
    strategy: 'string',
    agentTypes: 'array',
    coordinationLevel: 'string',
    objectives: 'array'
  },

  // Communication Message
  AGENT_MESSAGE: {
    fromAgent: 'string',
    toAgent: 'string',
    type: 'string',
    content: 'object',
    timestamp: 'number',
    priority: 'string'
  }
};

/**
 * Julia API Types
 */
export const JULIA_API_TYPES = {
  // Analysis Request
  ANALYSIS_REQUEST: {
    walletAddress: 'string',
    analysisType: 'string',
    parameters: 'object',
    timeout: 'number',
    priority: 'string'
  },

  // Analysis Response
  ANALYSIS_RESPONSE: {
    id: 'string',
    status: 'string',
    progress: 'number',
    results: 'object',
    metadata: 'object',
    startTime: 'number',
    duration: 'number'
  },

  // Computation Job
  COMPUTATION_JOB: {
    algorithm: 'string',
    data: 'object',
    parameters: 'object',
    priority: 'string',
    estimatedDuration: 'number'
  },

  // Performance Metrics
  PERFORMANCE_METRICS: {
    cpuUsage: 'number',
    memoryUsage: 'number',
    activeJobs: 'number',
    queueLength: 'number',
    averageJobTime: 'number',
    successRate: 'number'
  }
};

/**
 * WebSocket Message Types
 */
export const WEBSOCKET_MESSAGE_TYPES = {
  // Connection
  CONNECT: 'connect',
  DISCONNECT: 'disconnect',
  PING: 'ping',
  PONG: 'pong',

  // Investigation Updates
  INVESTIGATION_STARTED: 'investigation_started',
  INVESTIGATION_PROGRESS: 'investigation_progress',
  INVESTIGATION_COMPLETED: 'investigation_completed',
  INVESTIGATION_FAILED: 'investigation_failed',

  // Agent Updates
  AGENT_STATUS_UPDATE: 'agent_status_update',
  AGENT_TASK_ASSIGNED: 'agent_task_assigned',
  AGENT_TASK_COMPLETED: 'agent_task_completed',

  // System Updates
  SYSTEM_ALERT: 'system_alert',
  HEALTH_UPDATE: 'health_update',
  SERVICE_STATUS: 'service_status'
};

/**
 * WebSocket Message Structure
 * @typedef {Object} WebSocketMessage
 * @property {string} type - Message type
 * @property {*} data - Message data
 * @property {string} source - Message source service
 * @property {number} timestamp - Message timestamp
 * @property {string} id - Unique message ID
 */
export const createWebSocketMessage = (type, data, source = 'unknown') => ({
  type,
  data,
  source,
  timestamp: Date.now(),
  id: generateMessageId()
});

/**
 * Pagination Types
 */
export const PAGINATION_TYPES = {
  REQUEST: {
    page: 'number',
    limit: 'number',
    sortBy: 'string',
    sortOrder: 'string',
    filters: 'object'
  },

  RESPONSE: {
    data: 'array',
    pagination: {
      page: 'number',
      limit: 'number',
      total: 'number',
      totalPages: 'number',
      hasNext: 'boolean',
      hasPrev: 'boolean'
    }
  }
};

/**
 * Health Check Types
 */
export const HEALTH_CHECK_TYPES = {
  REQUEST: {
    includeDetails: 'boolean',
    timeout: 'number'
  },

  RESPONSE: {
    status: 'string', // 'healthy', 'unhealthy', 'degraded'
    timestamp: 'number',
    uptime: 'number',
    version: 'string',
    services: 'object',
    metrics: 'object'
  }
};

/**
 * Upload Types
 */
export const UPLOAD_TYPES = {
  REQUEST: {
    file: 'File',
    type: 'string',
    metadata: 'object'
  },

  RESPONSE: {
    id: 'string',
    filename: 'string',
    size: 'number',
    type: 'string',
    url: 'string',
    uploadedAt: 'string'
  }
};

/**
 * Utility Functions
 */

// Generate unique request ID
const generateRequestId = () => {
  return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
};

// Generate unique message ID
const generateMessageId = () => {
  return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
};

/**
 * Type Validation Functions
 */
export const validateType = (value, expectedType, fieldName = 'field') => {
  const actualType = typeof value;

  if (expectedType === 'array' && !Array.isArray(value)) {
    throw new Error(`${fieldName} should be an array, got ${actualType}`);
  }

  if (expectedType === 'object' && (actualType !== 'object' || Array.isArray(value) || value === null)) {
    throw new Error(`${fieldName} should be an object, got ${actualType}`);
  }

  if (expectedType !== 'array' && expectedType !== 'object' && actualType !== expectedType) {
    throw new Error(`${fieldName} should be ${expectedType}, got ${actualType}`);
  }

  return true;
};

// Validate API request structure
export const validateApiRequest = (request, expectedStructure, structureName = 'request') => {
  if (!request || typeof request !== 'object') {
    throw new Error(`${structureName} must be an object`);
  }

  for (const [field, expectedType] of Object.entries(expectedStructure)) {
    if (request.hasOwnProperty(field)) {
      validateType(request[field], expectedType, `${structureName}.${field}`);
    }
  }

  return true;
};

// Type checking utilities
export const isValidApiResponse = (response) => {
  try {
    return response &&
           typeof response === 'object' &&
           typeof response.success === 'boolean' &&
           response.hasOwnProperty('data') &&
           typeof response.timestamp === 'number';
  } catch {
    return false;
  }
};

export const isValidApiError = (error) => {
  try {
    return error &&
           typeof error === 'object' &&
           typeof error.code === 'string' &&
           typeof error.message === 'string' &&
           typeof error.type === 'string';
  } catch {
    return false;
  }
};

export const isValidWebSocketMessage = (message) => {
  try {
    return message &&
           typeof message === 'object' &&
           typeof message.type === 'string' &&
           message.hasOwnProperty('data') &&
           typeof message.timestamp === 'number';
  } catch {
    return false;
  }
};

export default {
  HTTP_STATUS,
  BACKEND_API_TYPES,
  A2A_API_TYPES,
  JULIA_API_TYPES,
  WEBSOCKET_MESSAGE_TYPES,
  PAGINATION_TYPES,
  HEALTH_CHECK_TYPES,
  UPLOAD_TYPES,
  createApiResponse,
  createApiError,
  createWebSocketMessage,
  validateType,
  validateApiRequest,
  isValidApiResponse,
  isValidApiError,
  isValidWebSocketMessage
};
