/**
 * Ghost Wallet Hunter - WebSocket Service
 * =======================================
 *
 * Real-time communication service for live investigation updates, agent status,
 * and system notifications. Handles connections to all WebSocket endpoints.
 */

import { CURRENT_URLS, IS_DEVELOPMENT } from '../config/environment.js';
import { WEBSOCKET_CONFIG, ERROR_CONSTANTS } from '../config/constants.js';

/**
 * WebSocket Connection Manager
 */
class WebSocketManager {
  constructor() {
    this.connections = new Map();
    this.subscribers = new Map();
    this.reconnectTimers = new Map();
    this.heartbeatTimers = new Map();
    this.isConnecting = new Set();
  }

  /**
   * Create WebSocket connection
   * @param {string} endpoint - WebSocket endpoint identifier
   * @param {string} url - WebSocket URL
   * @param {Object} options - Connection options
   */
  async connect(endpoint, url, options = {}) {
    if (this.isConnecting.has(endpoint)) {
      throw new Error(`Already connecting to ${endpoint}`);
    }

    if (this.connections.has(endpoint)) {
      return this.connections.get(endpoint);
    }

    this.isConnecting.add(endpoint);

    try {
      const ws = new WebSocket(url);

      // Configure connection
      ws.endpoint = endpoint;
      ws.options = { ...WEBSOCKET_CONFIG.DEFAULT_OPTIONS, ...options };
      ws.reconnectAttempts = 0;
      ws.lastHeartbeat = Date.now();

      // Set up event handlers
      this.setupEventHandlers(ws);

      // Wait for connection
      await this.waitForConnection(ws);

      this.connections.set(endpoint, ws);
      this.isConnecting.delete(endpoint);

      if (IS_DEVELOPMENT) {
        console.log(`🔗 WebSocket connected: ${endpoint}`);
      }

      return ws;

    } catch (error) {
      this.isConnecting.delete(endpoint);
      console.error(`🚨 WebSocket connection failed: ${endpoint}`, error);
      throw error;
    }
  }

  /**
   * Set up WebSocket event handlers
   * @private
   */
  setupEventHandlers(ws) {
    ws.onopen = (event) => {
      ws.reconnectAttempts = 0;
      this.startHeartbeat(ws);
      this.notifySubscribers(ws.endpoint, 'connected', { event });
    };

    ws.onmessage = (event) => {
      ws.lastHeartbeat = Date.now();

      try {
        const data = JSON.parse(event.data);
        this.handleMessage(ws.endpoint, data, event);
      } catch (error) {
        console.warn(`⚠️ Invalid JSON from ${ws.endpoint}:`, event.data);
        this.notifySubscribers(ws.endpoint, 'error', {
          error: 'Invalid JSON',
          data: event.data
        });
      }
    };

    ws.onclose = (event) => {
      this.stopHeartbeat(ws);
      this.connections.delete(ws.endpoint);

      if (IS_DEVELOPMENT) {
        console.log(`🔌 WebSocket closed: ${ws.endpoint}`, event.code, event.reason);
      }

      this.notifySubscribers(ws.endpoint, 'disconnected', { event });

      // Auto-reconnect if not intentional close
      if (event.code !== 1000 && ws.options.autoReconnect) {
        this.scheduleReconnect(ws);
      }
    };

    ws.onerror = (event) => {
      console.error(`🚨 WebSocket error: ${ws.endpoint}`, event);
      this.notifySubscribers(ws.endpoint, 'error', { event });
    };
  }

  /**
   * Wait for WebSocket connection to open
   * @private
   */
  waitForConnection(ws) {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error(`WebSocket connection timeout: ${ws.endpoint}`));
      }, WEBSOCKET_CONFIG.CONNECTION_TIMEOUT);

      ws.addEventListener('open', () => {
        clearTimeout(timeout);
        resolve(ws);
      });

      ws.addEventListener('error', (error) => {
        clearTimeout(timeout);
        reject(error);
      });
    });
  }

  /**
   * Handle incoming WebSocket message
   * @private
   */
  handleMessage(endpoint, data, rawEvent) {
    const messageType = data.type || 'message';

    // Handle heartbeat/ping messages
    if (messageType === 'ping') {
      this.sendPong(endpoint);
      return;
    }

    if (messageType === 'pong') {
      // Heartbeat acknowledged
      return;
    }

    // Notify subscribers
    this.notifySubscribers(endpoint, messageType, data, rawEvent);
  }

  /**
   * Send pong response to ping
   * @private
   */
  sendPong(endpoint) {
    const ws = this.connections.get(endpoint);
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
    }
  }

  /**
   * Start heartbeat for connection health
   * @private
   */
  startHeartbeat(ws) {
    if (!ws.options.heartbeat) return;

    const timer = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        // Check if we received recent data
        const timeSinceLastHeartbeat = Date.now() - ws.lastHeartbeat;

        if (timeSinceLastHeartbeat > WEBSOCKET_CONFIG.HEARTBEAT_TIMEOUT) {
          console.warn(`⚠️ WebSocket heartbeat timeout: ${ws.endpoint}`);
          ws.close(4000, 'Heartbeat timeout');
          return;
        }

        // Send ping
        ws.send(JSON.stringify({
          type: 'ping',
          timestamp: Date.now()
        }));
      }
    }, WEBSOCKET_CONFIG.HEARTBEAT_INTERVAL);

    this.heartbeatTimers.set(ws.endpoint, timer);
  }

  /**
   * Stop heartbeat timer
   * @private
   */
  stopHeartbeat(ws) {
    const timer = this.heartbeatTimers.get(ws.endpoint);
    if (timer) {
      clearInterval(timer);
      this.heartbeatTimers.delete(ws.endpoint);
    }
  }

  /**
   * Schedule reconnection attempt
   * @private
   */
  scheduleReconnect(ws) {
    if (ws.reconnectAttempts >= WEBSOCKET_CONFIG.MAX_RECONNECT_ATTEMPTS) {
      console.error(`🚨 Max reconnection attempts (${WEBSOCKET_CONFIG.MAX_RECONNECT_ATTEMPTS}) reached for ${ws.endpoint}`);
      this.notifySubscribers(ws.endpoint, 'reconnect_failed', {
        attempts: ws.reconnectAttempts
      });
      return;
    }

    const delay = Math.min(
      WEBSOCKET_CONFIG.RECONNECT_DELAY * Math.pow(WEBSOCKET_CONFIG.BACKOFF_MULTIPLIER, ws.reconnectAttempts),
      WEBSOCKET_CONFIG.MAX_RECONNECT_DELAY
    );

    ws.reconnectAttempts++;

    if (IS_DEVELOPMENT) {
      console.log(`🔄 Scheduling reconnect for ${ws.endpoint} in ${delay}ms (attempt ${ws.reconnectAttempts}/${WEBSOCKET_CONFIG.MAX_RECONNECT_ATTEMPTS})`);
    }

    const timer = setTimeout(() => {
      this.reconnectTimers.delete(ws.endpoint);
      this.reconnect(ws);
    }, delay);

    this.reconnectTimers.set(ws.endpoint, timer);
  }

  /**
   * Attempt to reconnect WebSocket
   * @private
   */
  async reconnect(ws) {
    // Double check attempts limit before trying to reconnect
    if (ws.reconnectAttempts >= WEBSOCKET_CONFIG.MAX_RECONNECT_ATTEMPTS) {
      console.error(`🚨 Max reconnection attempts (${WEBSOCKET_CONFIG.MAX_RECONNECT_ATTEMPTS}) reached for ${ws.endpoint} - stopping`);
      this.notifySubscribers(ws.endpoint, 'reconnect_failed', {
        attempts: ws.reconnectAttempts
      });
      return;
    }

    try {
      const url = ws.url;
      const options = ws.options;
      const endpoint = ws.endpoint;

      await this.connect(endpoint, url, options);

      this.notifySubscribers(endpoint, 'reconnected', {
        attempts: ws.reconnectAttempts
      });

    } catch (error) {
      console.error(`🚨 Reconnection failed for ${ws.endpoint}:`, error);

      // Only schedule another reconnection if we haven't hit the limit
      if (ws.reconnectAttempts < WEBSOCKET_CONFIG.MAX_RECONNECT_ATTEMPTS) {
        this.scheduleReconnect(ws);
      } else {
        console.error(`🚨 Max reconnection attempts reached for ${ws.endpoint} - giving up`);
        this.notifySubscribers(ws.endpoint, 'reconnect_failed', {
          attempts: ws.reconnectAttempts
        });
      }
    }
  }

  /**
   * Send message through WebSocket
   */
  send(endpoint, message) {
    const ws = this.connections.get(endpoint);

    if (!ws) {
      throw new Error(`No WebSocket connection for endpoint: ${endpoint}`);
    }

    if (ws.readyState !== WebSocket.OPEN) {
      throw new Error(`WebSocket not ready for endpoint: ${endpoint}`);
    }

    const data = typeof message === 'string' ? message : JSON.stringify(message);
    ws.send(data);

    if (IS_DEVELOPMENT) {
      console.log(`📤 WebSocket sent to ${endpoint}:`, message);
    }
  }

  /**
   * Subscribe to WebSocket events
   */
  subscribe(endpoint, eventType, callback) {
    const key = `${endpoint}:${eventType}`;

    if (!this.subscribers.has(key)) {
      this.subscribers.set(key, new Set());
    }

    this.subscribers.get(key).add(callback);

    // Return unsubscribe function
    return () => {
      const callbacks = this.subscribers.get(key);
      if (callbacks) {
        callbacks.delete(callback);
        if (callbacks.size === 0) {
          this.subscribers.delete(key);
        }
      }
    };
  }

  /**
   * Notify subscribers of events
   * @private
   */
  notifySubscribers(endpoint, eventType, data, rawEvent) {
    const key = `${endpoint}:${eventType}`;
    const callbacks = this.subscribers.get(key);

    if (callbacks) {
      callbacks.forEach(callback => {
        try {
          callback(data, rawEvent);
        } catch (error) {
          console.error(`🚨 Subscriber callback error for ${key}:`, error);
        }
      });
    }

    // Also notify wildcard subscribers
    const wildcardKey = `${endpoint}:*`;
    const wildcardCallbacks = this.subscribers.get(wildcardKey);

    if (wildcardCallbacks) {
      wildcardCallbacks.forEach(callback => {
        try {
          callback(eventType, data, rawEvent);
        } catch (error) {
          console.error(`🚨 Wildcard subscriber callback error for ${wildcardKey}:`, error);
        }
      });
    }
  }

  /**
   * Disconnect WebSocket
   */
  disconnect(endpoint) {
    const ws = this.connections.get(endpoint);

    if (ws) {
      // Clear timers
      this.stopHeartbeat(ws);

      const reconnectTimer = this.reconnectTimers.get(endpoint);
      if (reconnectTimer) {
        clearTimeout(reconnectTimer);
        this.reconnectTimers.delete(endpoint);
      }

      // Close connection
      ws.close(1000, 'Manual disconnect');
      this.connections.delete(endpoint);

      if (IS_DEVELOPMENT) {
        console.log(`🔌 WebSocket disconnected: ${endpoint}`);
      }
    }
  }

  /**
   * Disconnect all WebSockets
   */
  disconnectAll() {
    Array.from(this.connections.keys()).forEach(endpoint => {
      this.disconnect(endpoint);
    });
  }

  /**
   * Get connection status
   */
  getConnectionStatus(endpoint) {
    const ws = this.connections.get(endpoint);

    if (!ws) {
      return { status: 'disconnected', endpoint };
    }

    const statusMap = {
      [WebSocket.CONNECTING]: 'connecting',
      [WebSocket.OPEN]: 'connected',
      [WebSocket.CLOSING]: 'closing',
      [WebSocket.CLOSED]: 'disconnected'
    };

    return {
      status: statusMap[ws.readyState] || 'unknown',
      endpoint,
      reconnectAttempts: ws.reconnectAttempts || 0,
      lastHeartbeat: ws.lastHeartbeat
    };
  }

  /**
   * Get all connection statuses
   */
  getAllConnectionStatuses() {
    const statuses = {};
    this.connections.forEach((ws, endpoint) => {
      statuses[endpoint] = this.getConnectionStatus(endpoint);
    });
    return statuses;
  }
}

// Create singleton WebSocket manager
const wsManager = new WebSocketManager();

/**
 * Investigation WebSocket Service
 */
export const investigationWebSocketService = {
  /**
   * Connect to backend investigation updates
   */
  async connectToBackend() {
    const url = `${CURRENT_URLS.BACKEND_WS}/investigations`;
    return wsManager.connect('backend_investigations', url, {
      autoReconnect: true,
      heartbeat: true
    });
  },

  /**
   * Subscribe to investigation updates
   */
  subscribeToInvestigationUpdates(investigationId, callback) {
    return wsManager.subscribe('backend_investigations', 'investigation_update', (data) => {
      if (data.investigation_id === investigationId) {
        callback(data);
      }
    });
  },

  /**
   * Subscribe to all investigation updates
   */
  subscribeToAllInvestigations(callback) {
    return wsManager.subscribe('backend_investigations', 'investigation_update', callback);
  }
};

/**
 * Agent WebSocket Service (A2A)
 */
export const agentWebSocketService = {
  /**
   * Connect to A2A agent coordination
   */
  async connectToA2A() {
    const url = `${CURRENT_URLS.A2A_WS}/agents`;
    return wsManager.connect('a2a_agents', url, {
      autoReconnect: true,
      heartbeat: true
    });
  },

  /**
   * Subscribe to agent status updates
   */
  subscribeToAgentStatus(agentId, callback) {
    return wsManager.subscribe('a2a_agents', 'agent_status', (data) => {
      if (data.agent_id === agentId) {
        callback(data);
      }
    });
  },

  /**
   * Subscribe to task coordination
   */
  subscribeToTaskUpdates(taskId, callback) {
    return wsManager.subscribe('a2a_agents', 'task_update', (data) => {
      if (data.task_id === taskId) {
        callback(data);
      }
    });
  },

  /**
   * Subscribe to swarm coordination
   */
  subscribeToSwarmUpdates(swarmId, callback) {
    return wsManager.subscribe('a2a_agents', 'swarm_update', (data) => {
      if (data.swarm_id === swarmId) {
        callback(data);
      }
    });
  }
};

/**
 * Julia WebSocket Service
 */
export const juliaWebSocketService = {
  /**
   * Connect to Julia core analysis updates
   */
  async connectToJulia() {
    const url = `${CURRENT_URLS.JULIA_WS}/analysis`;
    return wsManager.connect('julia_analysis', url, {
      autoReconnect: true,
      heartbeat: true
    });
  },

  /**
   * Subscribe to analysis progress
   */
  subscribeToAnalysisProgress(analysisId, callback) {
    return wsManager.subscribe('julia_analysis', 'analysis_progress', (data) => {
      if (data.analysis_id === analysisId) {
        callback(data);
      }
    });
  },

  /**
   * Subscribe to computation updates
   */
  subscribeToComputationUpdates(jobId, callback) {
    return wsManager.subscribe('julia_analysis', 'computation_update', (data) => {
      if (data.job_id === jobId) {
        callback(data);
      }
    });
  }
};

/**
 * System WebSocket Service
 */
export const systemWebSocketService = {
  /**
   * Connect to system notifications
   */
  async connectToSystem() {
    const url = `${CURRENT_URLS.BACKEND_WS}/system`;
    return wsManager.connect('system_notifications', url, {
      autoReconnect: true,
      heartbeat: true
    });
  },

  /**
   * Subscribe to system alerts
   */
  subscribeToSystemAlerts(callback) {
    return wsManager.subscribe('system_notifications', 'alert', callback);
  },

  /**
   * Subscribe to health status updates
   */
  subscribeToHealthUpdates(callback) {
    return wsManager.subscribe('system_notifications', 'health_update', callback);
  }
};

// Export comprehensive WebSocket service
export const webSocketService = {
  // Core manager
  manager: wsManager,

  // Specialized services
  investigations: investigationWebSocketService,
  agents: agentWebSocketService,
  julia: juliaWebSocketService,
  system: systemWebSocketService,

  // Utility methods
  async connectAll() {
    const connections = await Promise.allSettled([
      investigationWebSocketService.connectToBackend(),
      agentWebSocketService.connectToA2A(),
      juliaWebSocketService.connectToJulia(),
      systemWebSocketService.connectToSystem()
    ]);

    const results = connections.map((result, index) => ({
      service: ['backend', 'a2a', 'julia', 'system'][index],
      status: result.status,
      connection: result.status === 'fulfilled' ? result.value : null,
      error: result.status === 'rejected' ? result.reason : null
    }));

    if (IS_DEVELOPMENT) {
      console.log('🔗 WebSocket connections:', results);
    }

    return results;
  },

  disconnectAll() {
    wsManager.disconnectAll();
  },

  getConnectionStatuses() {
    return wsManager.getAllConnectionStatuses();
  }
};

export default webSocketService;
