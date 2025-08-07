/**
 * Ghost Wallet Hunter - Types Export Index
 * =======================================
 *
 * Centralized export for all type definitions and interfaces.
 * Provides easy imports for type safety across the application.
 */

// API Types
export {
  // HTTP Status Constants
  HTTP_STATUS,

  // API Type Structures
  BACKEND_API_TYPES,
  A2A_API_TYPES,
  JULIA_API_TYPES,

  // WebSocket Types
  WEBSOCKET_MESSAGE_TYPES,

  // Validation Functions
  validateHTTPStatus,
  validateAPIResponse,
  validateWebSocketMessage,

  // Type Checking Utilities
  isValidResponse,
  isErrorResponse,
  isSuccessResponse,
  isWebSocketMessage,
  isValidMessageType,
  getMessageType,

  // Default Export
  default as ApiTypes
} from './api.types.js';

// Investigation Types
export {
  // Status and Type Enums
  INVESTIGATION_STATUS,
  INVESTIGATION_TYPES,
  INVESTIGATION_PRIORITY,
  RISK_LEVELS,
  CONFIDENCE_LEVELS,
  FLAGGED_ACTIVITY_TYPES,
  ACTIVITY_SEVERITY,

  // Factory Functions
  createInvestigationRequest,
  createInvestigationResponse,
  createInvestigationResults,
  createFlaggedActivity,
  createProgressUpdate,
  createAgentAssignment,
  createRecommendation,

  // Utility Functions
  getConfidenceLevel,
  getRiskLevel,

  // Validation Functions
  isValidInvestigationStatus,
  isValidInvestigationType,
  isValidRiskLevel,
  isValidFlaggedActivityType,
  validateInvestigationRequest,

  // Progress Functions
  calculateOverallProgress,
  isInvestigationComplete,

  // Default Export
  default as InvestigationTypes
} from './investigation.types.js';

/**
 * Combined Type Exports for Convenience
 */

// All Status Enums
export const ALL_STATUS_TYPES = {
  HTTP: 'HTTP_STATUS',
  INVESTIGATION: 'INVESTIGATION_STATUS',
  WEBSOCKET: 'WEBSOCKET_MESSAGE_TYPES'
};

// Common Type Validators
export const COMMON_VALIDATORS = {
  // HTTP Validation
  isValidHTTPStatus: validateHTTPStatus,
  isValidAPIResponse: validateAPIResponse,

  // Investigation Validation
  isValidInvestigation: validateInvestigationRequest,
  isInvestigationComplete,

  // WebSocket Validation
  isValidWebSocketMessage: validateWebSocketMessage,
  isValidMessageType
};

// Type Factories
export const TYPE_FACTORIES = {
  // Investigation Factories
  createInvestigation: createInvestigationRequest,
  createResults: createInvestigationResults,
  createActivity: createFlaggedActivity,
  createProgress: createProgressUpdate,
  createAgent: createAgentAssignment,
  createRecommendation,

  // Progress Calculation
  calculateProgress: calculateOverallProgress
};

// Risk Assessment Utilities
export const RISK_UTILITIES = {
  getRiskLevel,
  getConfidenceLevel,
  isValidRiskLevel,
  levels: {
    RISK: RISK_LEVELS,
    CONFIDENCE: CONFIDENCE_LEVELS
  }
};

// API Integration Utilities
export const API_UTILITIES = {
  status: HTTP_STATUS,
  types: {
    BACKEND: 'BACKEND_API_TYPES',
    A2A: 'A2A_API_TYPES',
    JULIA: 'JULIA_API_TYPES'
  },
  validators: {
    isSuccessResponse,
    isErrorResponse,
    isValidResponse
  }
};

// WebSocket Utilities
export const WEBSOCKET_UTILITIES = {
  messageTypes: WEBSOCKET_MESSAGE_TYPES,
  validators: {
    isWebSocketMessage,
    isValidMessageType
  },
  getMessageType
};

/**
 * Type Definition Maps for Runtime Use
 */

// Status Code Maps
export const STATUS_MAPS = {
  // HTTP Status to Human Readable
  HTTP_STATUS_TEXT: {
    200: 'OK',
    201: 'Created',
    202: 'Accepted',
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    429: 'Too Many Requests',
    500: 'Internal Server Error',
    502: 'Bad Gateway',
    503: 'Service Unavailable'
  },

  // Investigation Status to Human Readable
  INVESTIGATION_STATUS_TEXT: {
    pending: 'Pending',
    initializing: 'Initializing',
    running: 'Running',
    analyzing: 'Analyzing',
    consolidating: 'Consolidating',
    completed: 'Completed',
    failed: 'Failed',
    cancelled: 'Cancelled',
    timeout: 'Timeout'
  },

  // Risk Level to Human Readable
  RISK_LEVEL_TEXT: {
    very_low: 'Very Low',
    low: 'Low',
    medium: 'Medium',
    high: 'High',
    very_high: 'Very High',
    critical: 'Critical'
  }
};

// Color Maps for UI
export const COLOR_MAPS = {
  // Risk Level Colors
  RISK_COLORS: {
    very_low: '#10B981',    // Green
    low: '#84CC16',         // Light Green
    medium: '#F59E0B',      // Amber
    high: '#EF4444',        // Red
    very_high: '#DC2626',   // Dark Red
    critical: '#7C2D12'     // Very Dark Red
  },

  // Investigation Status Colors
  STATUS_COLORS: {
    pending: '#6B7280',     // Gray
    initializing: '#3B82F6', // Blue
    running: '#10B981',     // Green
    analyzing: '#8B5CF6',   // Purple
    consolidating: '#F59E0B', // Amber
    completed: '#059669',   // Dark Green
    failed: '#DC2626',      // Red
    cancelled: '#6B7280',   // Gray
    timeout: '#EF4444'      // Red
  },

  // Activity Severity Colors
  SEVERITY_COLORS: {
    1: '#10B981',  // Info - Green
    2: '#84CC16',  // Low - Light Green
    4: '#F59E0B',  // Medium - Amber
    6: '#EF4444',  // High - Red
    8: '#DC2626',  // Critical - Dark Red
    10: '#7C2D12'  // Severe - Very Dark Red
  }
};

/**
 * Default Export - All Types Combined
 */
export default {
  // API Types
  ApiTypes,
  HTTP_STATUS,
  BACKEND_API_TYPES,
  A2A_API_TYPES,
  JULIA_API_TYPES,
  WEBSOCKET_MESSAGE_TYPES,

  // Investigation Types
  InvestigationTypes,
  INVESTIGATION_STATUS,
  INVESTIGATION_TYPES,
  INVESTIGATION_PRIORITY,
  RISK_LEVELS,
  CONFIDENCE_LEVELS,
  FLAGGED_ACTIVITY_TYPES,
  ACTIVITY_SEVERITY,

  // Utilities
  COMMON_VALIDATORS,
  TYPE_FACTORIES,
  RISK_UTILITIES,
  API_UTILITIES,
  WEBSOCKET_UTILITIES,

  // Maps
  STATUS_MAPS,
  COLOR_MAPS,

  // Quick Access
  status: HTTP_STATUS,
  investigation: INVESTIGATION_STATUS,
  risk: RISK_LEVELS,
  confidence: CONFIDENCE_LEVELS,

  // Validators
  validate: COMMON_VALIDATORS,
  create: TYPE_FACTORIES,
  colors: COLOR_MAPS
};
