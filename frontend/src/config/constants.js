/**
 * Ghost Wallet Hunter - Global Constants
 * ======================================
 *
 * All global constants, enums, and configuration values used across the application.
 * Organized by category for better maintainability.
 */

// Application Constants
export const APP_CONSTANTS = {
  NAME: 'Ghost Wallet Hunter',
  DESCRIPTION: 'AI-powered blockchain analysis for detecting suspicious wallet clusters',
  VERSION: '2.0.0',
  AUTHOR: 'Ghost Team',
  GITHUB_URL: 'https://github.com/lipeamarok/ghost-wallet-hunter'
};

// Investigation Constants
export const INVESTIGATION_CONSTANTS = {
  // Investigation types
  TYPES: {
    QUICK: 'quick',
    COMPREHENSIVE: 'comprehensive',
    DEEP: 'deep',
    CUSTOM: 'custom'
  },

  // Investigation status
  STATUS: {
    PENDING: 'pending',
    RUNNING: 'running',
    COMPLETED: 'completed',
    FAILED: 'failed',
    CANCELLED: 'cancelled'
  },

  // Risk levels
  RISK_LEVELS: {
    VERY_LOW: 'very_low',
    LOW: 'low',
    MEDIUM: 'medium',
    HIGH: 'high',
    VERY_HIGH: 'very_high',
    CRITICAL: 'critical'
  },

  // Timeouts (in milliseconds)
  TIMEOUTS: {
    QUICK: 30000,      // 30 seconds
    STANDARD: 120000,  // 2 minutes
    COMPREHENSIVE: 300000, // 5 minutes
    DEEP: 600000       // 10 minutes
  }
};

// Detective Agents Constants
export const DETECTIVE_CONSTANTS = {
  // Available detectives (7 real agents as defined in JuliaOS)
  DETECTIVES: {
    POIROT: 'poirot',
    MARPLE: 'marple',
    SPADE: 'spade',
    MARLOWEE: 'marlowee',
    DUPIN: 'dupin',
    SHADOW: 'shadow',
    RAVEN: 'raven'
  },

  // Detective specialties (as defined in JuliaOS DetectiveAgents.jl)
  SPECIALTIES: {
    METHODICAL_TRANSACTION_ANALYSIS: 'methodical_transaction_analysis',
    PATTERN_ANOMALY_DETECTION: 'pattern_anomaly_detection',
    HARD_BOILED_INVESTIGATION_COMPLIANCE: 'hard_boiled_investigation_compliance',
    DEEP_ANALYSIS_INVESTIGATION: 'deep_analysis_investigation',
    ANALYTICAL_REASONING_INVESTIGATION: 'analytical_reasoning_investigation',
    STEALTH_INVESTIGATION: 'stealth_investigation',
    DARK_INVESTIGATION: 'dark_investigation'
  },

  // Detective descriptions
  DESCRIPTIONS: {
    POIROT: {
      name: 'Detective Hercule Poirot',
      specialty: 'methodical_transaction_analysis',
      persona: 'Belgian master of deduction applied to blockchain analysis',
      catchphrase: 'Ah, mon ami, the little grey cells, they work!',
      skills: ['transaction_analysis', 'methodical_investigation', 'pattern_recognition', 'deductive_reasoning']
    },
    MARPLE: {
      name: 'Detective Miss Jane Marple',
      specialty: 'pattern_anomaly_detection',
      persona: 'Perceptive observer who notices details others miss',
      catchphrase: 'Oh my dear, that\'s rather peculiar, isn\'t it?',
      skills: ['pattern_detection', 'anomaly_analysis', 'behavioral_profiling', 'social_network_analysis']
    },
    SPADE: {
      name: 'Detective Sam Spade',
      specialty: 'hard_boiled_investigation_compliance',
      persona: 'Hard-boiled private detective with compliance expertise',
      catchphrase: 'When you\'re slapped, you\'ll take it and like it.',
      skills: ['risk_assessment', 'threat_analysis', 'criminal_pattern_detection', 'compliance_monitoring', 'financial_crime_detection']
    },
    MARLOWEE: {
      name: 'Detective Philip Marlowe',
      specialty: 'deep_analysis_investigation',
      persona: 'Knight of the mean streets with narrative depth',
      catchphrase: 'Down these mean streets a man must go who is not himself mean.',
      skills: ['deep_analysis', 'narrative_investigation', 'corruption_detection', 'multi_layer_analysis']
    },
    DUPIN: {
      name: 'Detective Auguste Dupin',
      specialty: 'analytical_reasoning_investigation',
      persona: 'Master of ratiocination and pure logic',
      catchphrase: 'The mental features discoursed of as the analytical, are, in themselves, but little susceptible of analysis.',
      skills: ['analytical_reasoning', 'logical_deduction', 'mathematical_analysis', 'systematic_investigation']
    },
    SHADOW: {
      name: 'The Shadow',
      specialty: 'stealth_investigation',
      persona: 'Master of stealth and hidden network investigations',
      catchphrase: 'Who knows what evil lurks in the hearts of wallets? The Shadow knows!',
      skills: ['stealth_analysis', 'hidden_network_mapping', 'covert_investigation', 'network_topology']
    },
    RAVEN: {
      name: 'Detective Raven',
      specialty: 'dark_investigation',
      persona: 'Investigator of the darkest blockchain mysteries',
      catchphrase: 'Nevermore shall evil transactions escape my vigilant gaze.',
      skills: ['dark_analysis', 'psychological_profiling', 'mysterious_pattern_detection', 'behavioral_analysis']
    }
  },

  // Detective status
  STATUS: {
    ACTIVE: 'active',
    INACTIVE: 'inactive',
    BUSY: 'busy',
    ERROR: 'error',
    MAINTENANCE: 'maintenance'
  }
};

// Blockchain Constants
export const BLOCKCHAIN_CONSTANTS = {
  // Supported networks
  NETWORKS: {
    SOLANA: 'solana',
    ETHEREUM: 'ethereum',
    BITCOIN: 'bitcoin',
    POLYGON: 'polygon',
    ARBITRUM: 'arbitrum',
    OPTIMISM: 'optimism'
  },

  // Address validation patterns
  ADDRESS_PATTERNS: {
    SOLANA: /^[1-9A-HJ-NP-Za-km-z]{32,44}$/,
    ETHEREUM: /^0x[a-fA-F0-9]{40}$/,
    BITCOIN: /^[13][a-km-zA-HZ1-9]{25,34}$|^bc1[a-z0-9]{39,59}$/
  },

  // Transaction limits
  TRANSACTION_LIMITS: {
    DEFAULT_DEPTH: 2,
    MAX_DEPTH: 5,
    DEFAULT_COUNT: 100,
    MAX_COUNT: 1000
  }
};

// API Constants
export const API_CONSTANTS = {
  // HTTP Methods
  METHODS: {
    GET: 'GET',
    POST: 'POST',
    PUT: 'PUT',
    DELETE: 'DELETE',
    PATCH: 'PATCH'
  },

  // Status codes
  STATUS_CODES: {
    OK: 200,
    CREATED: 201,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    TIMEOUT: 408,
    INTERNAL_ERROR: 500,
    BAD_GATEWAY: 502,
    SERVICE_UNAVAILABLE: 503
  },

  // Request timeouts (milliseconds)
  TIMEOUTS: {
    DEFAULT: 30000,     // 30 seconds
    UPLOAD: 60000,      // 1 minute
    INVESTIGATION: 300000, // 5 minutes
    HEALTH_CHECK: 5000  // 5 seconds
  },

  // Retry configuration
  RETRY: {
    DEFAULT_ATTEMPTS: 3,
    BACKOFF_MULTIPLIER: 2,
    INITIAL_DELAY: 1000
  }
};

// UI Constants
export const UI_CONSTANTS = {
  // Themes
  THEMES: {
    LIGHT: 'light',
    DARK: 'dark',
    AUTO: 'auto'
  },

  // Animation durations (milliseconds)
  ANIMATIONS: {
    FAST: 150,
    NORMAL: 300,
    SLOW: 500,
    VERY_SLOW: 1000
  },

  // Toast notification types
  TOAST_TYPES: {
    SUCCESS: 'success',
    ERROR: 'error',
    WARNING: 'warning',
    INFO: 'info',
    LOADING: 'loading'
  },

  // Page sizes for pagination
  PAGE_SIZES: {
    SMALL: 10,
    MEDIUM: 25,
    LARGE: 50,
    EXTRA_LARGE: 100
  }
};

// WebSocket Constants
export const WEBSOCKET_CONSTANTS = {
  // Connection states
  STATES: {
    CONNECTING: 'connecting',
    CONNECTED: 'connected',
    DISCONNECTED: 'disconnected',
    ERROR: 'error',
    RECONNECTING: 'reconnecting'
  },

  // Message types
  MESSAGE_TYPES: {
    INVESTIGATION_UPDATE: 'investigation_update',
    AGENT_STATUS: 'agent_status',
    SYSTEM_HEALTH: 'system_health',
    ERROR: 'error',
    PING: 'ping',
    PONG: 'pong'
  },

  // Reconnection settings (flattened for easier access)
  MAX_RECONNECT_ATTEMPTS: 3,       // Reduced from 5 to 3 to stop loops faster
  RECONNECT_DELAY: 1000,           // 1 second initial delay
  MAX_RECONNECT_DELAY: 10000,      // Max 10 seconds between attempts
  BACKOFF_MULTIPLIER: 2,           // Exponential backoff

  // Original nested structure for compatibility
  RECONNECTION: {
    MAX_ATTEMPTS: 3,
    INITIAL_DELAY: 1000,
    MAX_DELAY: 10000,
    BACKOFF_MULTIPLIER: 2
  }
};

// Error Constants
export const ERROR_CONSTANTS = {
  // Error types
  TYPES: {
    NETWORK: 'network_error',
    VALIDATION: 'validation_error',
    AUTHENTICATION: 'auth_error',
    AUTHORIZATION: 'authz_error',
    NOT_FOUND: 'not_found_error',
    TIMEOUT: 'timeout_error',
    SERVER: 'server_error',
    UNKNOWN: 'unknown_error'
  },

  // Error codes
  CODES: {
    INVALID_WALLET_ADDRESS: 'INVALID_WALLET_ADDRESS',
    INVESTIGATION_FAILED: 'INVESTIGATION_FAILED',
    SERVICE_UNAVAILABLE: 'SERVICE_UNAVAILABLE',
    RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
    INSUFFICIENT_FUNDS: 'INSUFFICIENT_FUNDS'
  }
};

// Local Storage Keys
export const STORAGE_KEYS = {
  THEME: 'ghost_theme',
  LAST_WALLET: 'ghost_last_wallet',
  INVESTIGATION_HISTORY: 'ghost_investigation_history',
  USER_PREFERENCES: 'ghost_user_preferences',
  API_CACHE: 'ghost_api_cache'
};

// Feature Flags
export const FEATURE_FLAGS = {
  ENABLE_DEBUG_MODE: false,
  ENABLE_ANALYTICS: false,
  ENABLE_EXPERIMENTAL_FEATURES: false,
  ENABLE_WEBSOCKET: true,
  ENABLE_CACHING: true,
  ENABLE_OFFLINE_MODE: false
};

// Individual exports for backward compatibility
export const INVESTIGATION_TYPES = INVESTIGATION_CONSTANTS.TYPES;
export const INVESTIGATION_STATUS = INVESTIGATION_CONSTANTS.STATUS;
export const AGENTS = DETECTIVE_CONSTANTS.DETECTIVES;
export const AGENT_CAPABILITIES = DETECTIVE_CONSTANTS.SPECIALTIES;
export const ANALYSIS_PRIORITIES = INVESTIGATION_CONSTANTS.RISK_LEVELS;
export const JULIA_CONFIG = {
  AGENTS: DETECTIVE_CONSTANTS.DETECTIVES,
  SPECIALTIES: DETECTIVE_CONSTANTS.SPECIALTIES,
  DESCRIPTIONS: DETECTIVE_CONSTANTS.DESCRIPTIONS
};
export const WEBSOCKET_CONFIG = WEBSOCKET_CONSTANTS;

// Export all constants as default
export default {
  APP_CONSTANTS,
  INVESTIGATION_CONSTANTS,
  DETECTIVE_CONSTANTS,
  BLOCKCHAIN_CONSTANTS,
  API_CONSTANTS,
  UI_CONSTANTS,
  WEBSOCKET_CONSTANTS,
  ERROR_CONSTANTS,
  STORAGE_KEYS,
  FEATURE_FLAGS
};
