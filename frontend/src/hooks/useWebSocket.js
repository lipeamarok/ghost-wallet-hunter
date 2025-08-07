/**
 * Ghost Wallet Hunter - useWebSocket Hook
 * =======================================
 *
 * React hook for managing WebSocket connections with automatic reconnection,
 * event handling, connection status monitoring, and real-time updates.
 * Provides a unified interface for all WebSocket interactions.
 */

import { useState, useEffect, useRef, useCallback } from 'react';
import { webSocketService } from '../services/index.js';
import { WEBSOCKET_CONFIG } from '../config/constants.js';
import { IS_DEVELOPMENT, APP_CONFIG } from '../config/environment.js';

/**
 * Connection states
 */
export const CONNECTION_STATES = {
  DISCONNECTED: 'disconnected',
  CONNECTING: 'connecting',
  CONNECTED: 'connected',
  RECONNECTING: 'reconnecting',
  ERROR: 'error'
};

/**
 * Main WebSocket hook for managing real-time connections
 * @param {Object} options - Configuration options
 * @param {boolean} options.autoConnect - Auto-connect on mount
 * @param {string[]} options.services - Services to connect to
 * @param {Function} options.onConnect - Connection callback
 * @param {Function} options.onDisconnect - Disconnection callback
 * @param {Function} options.onError - Error callback
 * @param {Function} options.onMessage - Global message callback
 */
export const useWebSocket = (options = {}) => {
  const {
    autoConnect = true,
    services = ['backend', 'a2a', 'julia', 'system'],
    onConnect,
    onDisconnect,
    onError,
    onMessage
  } = options;

  // Connection state
  const [connectionStates, setConnectionStates] = useState(() =>
    services.reduce((acc, service) => {
      acc[service] = CONNECTION_STATES.DISCONNECTED;
      return acc;
    }, {})
  );

  const [messages, setMessages] = useState([]);
  const [lastHeartbeat, setLastHeartbeat] = useState({});
  const [reconnectAttempts, setReconnectAttempts] = useState({});

  // Refs for cleanup
  const subscriptionsRef = useRef(new Map());
  const connectionsRef = useRef(new Map());

  /**
   * Update connection state for a service
   */
  const updateConnectionState = useCallback((service, state) => {
    setConnectionStates(prev => ({
      ...prev,
      [service]: state
    }));

    if (IS_DEVELOPMENT) {
      console.log(`🔗 WebSocket ${service}: ${state}`);
    }
  }, []);

  /**
   * Connect to specific service
   */
  const connectToService = useCallback(async (service) => {
    if (connectionStates[service] === CONNECTION_STATES.CONNECTING) {
      return; // Already connecting
    }

    updateConnectionState(service, CONNECTION_STATES.CONNECTING);

    try {
      let connection;

      switch (service) {
        case 'backend':
          connection = await webSocketService.investigations.connectToBackend();
          break;
        case 'a2a':
          connection = await webSocketService.agents.connectToA2A();
          break;
        case 'julia':
          connection = await webSocketService.julia.connectToJulia();
          break;
        case 'system':
          connection = await webSocketService.system.connectToSystem();
          break;
        default:
          throw new Error(`Unknown service: ${service}`);
      }

      connectionsRef.current.set(service, connection);
      updateConnectionState(service, CONNECTION_STATES.CONNECTED);
      setLastHeartbeat(prev => ({ ...prev, [service]: Date.now() }));
      setReconnectAttempts(prev => ({ ...prev, [service]: 0 }));

      if (onConnect) {
        onConnect(service, connection);
      }

      return connection;

    } catch (error) {
      updateConnectionState(service, CONNECTION_STATES.ERROR);

      if (onError) {
        onError(service, error);
      }

      // Schedule reconnection
      scheduleReconnect(service);
      throw error;
    }
  }, [connectionStates, updateConnectionState, onConnect, onError]);

  /**
   * Disconnect from specific service
   */
  const disconnectFromService = useCallback((service) => {
    const connection = connectionsRef.current.get(service);

    if (connection) {
      webSocketService.manager.disconnect(service);
      connectionsRef.current.delete(service);
      updateConnectionState(service, CONNECTION_STATES.DISCONNECTED);

      if (onDisconnect) {
        onDisconnect(service);
      }
    }
  }, [updateConnectionState, onDisconnect]);

  /**
   * Schedule reconnection for a service
   */
  const scheduleReconnect = useCallback((service) => {
    const attempts = reconnectAttempts[service] || 0;

    if (attempts >= WEBSOCKET_CONFIG.MAX_RECONNECT_ATTEMPTS) {
      console.warn(`🚨 Max reconnection attempts (${WEBSOCKET_CONFIG.MAX_RECONNECT_ATTEMPTS}) reached for ${service} - stopping`);
      updateConnectionState(service, CONNECTION_STATES.ERROR);
      return;
    }

    const delay = Math.min(
      WEBSOCKET_CONFIG.RECONNECT_DELAY * Math.pow(WEBSOCKET_CONFIG.BACKOFF_MULTIPLIER, attempts),
      WEBSOCKET_CONFIG.MAX_RECONNECT_DELAY
    );

    updateConnectionState(service, CONNECTION_STATES.RECONNECTING);
    setReconnectAttempts(prev => ({ ...prev, [service]: attempts + 1 }));

    console.log(`🔄 Scheduling reconnect for ${service} in ${delay}ms (attempt ${attempts + 1}/${WEBSOCKET_CONFIG.MAX_RECONNECT_ATTEMPTS})`);

    setTimeout(() => {
      connectToService(service);
    }, delay);
  }, [reconnectAttempts, updateConnectionState, connectToService]);

  /**
   * Connect to all configured services
   */
  const connectAll = useCallback(async () => {
    const results = await Promise.allSettled(
      services.map(service => connectToService(service))
    );

    return results.map((result, index) => ({
      service: services[index],
      success: result.status === 'fulfilled',
      connection: result.status === 'fulfilled' ? result.value : null,
      error: result.status === 'rejected' ? result.reason : null
    }));
  }, [services, connectToService]);

  /**
   * Disconnect from all services
   */
  const disconnectAll = useCallback(() => {
    services.forEach(service => disconnectFromService(service));
    subscriptionsRef.current.clear();
  }, [services, disconnectFromService]);

  /**
   * Subscribe to specific event from a service
   */
  const subscribe = useCallback((service, eventType, callback) => {
    const key = `${service}:${eventType}`;

    // Subscribe through WebSocket service
    const unsubscribe = webSocketService.manager.subscribe(service, eventType, (data, rawEvent) => {
      // Add message to history
      setMessages(prev => [
        ...prev.slice(-99), // Keep last 100 messages
        {
          service,
          eventType,
          data,
          timestamp: new Date(),
          id: `${service}_${Date.now()}_${Math.random()}`
        }
      ]);

      // Update heartbeat
      setLastHeartbeat(prev => ({ ...prev, [service]: Date.now() }));

      // Call local callback
      callback(data, rawEvent);

      // Call global message callback
      if (onMessage) {
        onMessage(service, eventType, data, rawEvent);
      }
    });

    // Store subscription
    subscriptionsRef.current.set(key, unsubscribe);

    // Return unsubscribe function
    return () => {
      const unsub = subscriptionsRef.current.get(key);
      if (unsub) {
        unsub();
        subscriptionsRef.current.delete(key);
      }
    };
  }, [onMessage]);

  /**
   * Send message to a service
   */
  const send = useCallback((service, message) => {
    try {
      webSocketService.manager.send(service, message);
      return true;
    } catch (error) {
      console.error(`Failed to send message to ${service}:`, error);
      return false;
    }
  }, []);

  /**
   * Get connection status for all services
   */
  const getConnectionStatus = useCallback(() => {
    return services.reduce((acc, service) => {
      acc[service] = {
        state: connectionStates[service],
        lastHeartbeat: lastHeartbeat[service],
        reconnectAttempts: reconnectAttempts[service] || 0,
        isConnected: connectionStates[service] === CONNECTION_STATES.CONNECTED,
        isConnecting: connectionStates[service] === CONNECTION_STATES.CONNECTING,
        isReconnecting: connectionStates[service] === CONNECTION_STATES.RECONNECTING,
        hasError: connectionStates[service] === CONNECTION_STATES.ERROR
      };
      return acc;
    }, {});
  }, [connectionStates, lastHeartbeat, reconnectAttempts, services]);

  /**
   * Auto-connect effect
   */
  useEffect(() => {
    // Check if WebSockets are enabled and should auto-connect
    if (autoConnect && APP_CONFIG.ENABLE_WEBSOCKETS && APP_CONFIG.WEBSOCKET_AUTO_CONNECT) {
      if (IS_DEVELOPMENT) {
        console.log('🔌 WebSocket auto-connect enabled in development mode');
      }
      connectAll();
    } else if (IS_DEVELOPMENT && !APP_CONFIG.WEBSOCKET_AUTO_CONNECT) {
      console.log('🔌 WebSocket auto-connect disabled in development mode. Use manual connection.');
    }

    return () => {
      disconnectAll();
    };
  }, [autoConnect, connectAll, disconnectAll]);

  /**
   * Heartbeat monitoring effect
   */
  useEffect(() => {
    const interval = setInterval(() => {
      const now = Date.now();

      Object.entries(lastHeartbeat).forEach(([service, timestamp]) => {
        if (connectionStates[service] === CONNECTION_STATES.CONNECTED) {
          const timeSinceHeartbeat = now - timestamp;

          if (timeSinceHeartbeat > WEBSOCKET_CONFIG.HEARTBEAT_TIMEOUT) {
            console.warn(`⚠️ Heartbeat timeout for ${service}`);
            disconnectFromService(service);
            scheduleReconnect(service);
          }
        }
      });
    }, WEBSOCKET_CONFIG.HEARTBEAT_INTERVAL);

    return () => clearInterval(interval);
  }, [connectionStates, lastHeartbeat, disconnectFromService, scheduleReconnect]);

  return {
    // Connection states
    connectionStates,
    connections: connectionsRef.current,

    // Connection management
    connectToService,
    disconnectFromService,
    connectAll,
    disconnectAll,

    // Event handling
    subscribe,
    send,

    // Status and monitoring
    getConnectionStatus,
    messages,
    lastHeartbeat,
    reconnectAttempts,

    // Computed states
    isAllConnected: services.every(service =>
      connectionStates[service] === CONNECTION_STATES.CONNECTED
    ),
    isAnyConnected: services.some(service =>
      connectionStates[service] === CONNECTION_STATES.CONNECTED
    ),
    isConnecting: services.some(service =>
      connectionStates[service] === CONNECTION_STATES.CONNECTING
    ),
    isReconnecting: services.some(service =>
      connectionStates[service] === CONNECTION_STATES.RECONNECTING
    ),
    hasErrors: services.some(service =>
      connectionStates[service] === CONNECTION_STATES.ERROR
    ),

    // Service-specific states
    backendConnected: connectionStates.backend === CONNECTION_STATES.CONNECTED,
    a2aConnected: connectionStates.a2a === CONNECTION_STATES.CONNECTED,
    juliaConnected: connectionStates.julia === CONNECTION_STATES.CONNECTED,
    systemConnected: connectionStates.system === CONNECTION_STATES.CONNECTED,

    // Utility functions
    clearMessages: () => setMessages([]),
    getRecentMessages: (count = 10) => messages.slice(-count),
    getServiceMessages: (service) => messages.filter(msg => msg.service === service),

    // Health check
    healthCheck: () => {
      const status = getConnectionStatus();
      const healthyServices = Object.values(status).filter(s => s.isConnected).length;
      const totalServices = services.length;

      return {
        healthy: healthyServices === totalServices,
        healthyServices,
        totalServices,
        healthRatio: totalServices > 0 ? healthyServices / totalServices : 0,
        status
      };
    }
  };
};

/**
 * Hook for subscribing to specific investigation updates
 */
export const useInvestigationWebSocket = (investigationId, options = {}) => {
  const { autoConnect = true } = options;
  const [updates, setUpdates] = useState([]);
  const [latestUpdate, setLatestUpdate] = useState(null);

  const webSocket = useWebSocket({
    autoConnect,
    services: ['backend'],
    onMessage: (service, eventType, data) => {
      if (eventType === 'investigation_update' && data.investigation_id === investigationId) {
        const update = { ...data, timestamp: new Date() };
        setUpdates(prev => [...prev.slice(-49), update]); // Keep last 50 updates
        setLatestUpdate(update);
      }
    }
  });

  return {
    ...webSocket,
    updates,
    latestUpdate,
    clearUpdates: () => setUpdates([])
  };
};

/**
 * Hook for agent status monitoring
 */
export const useAgentWebSocket = (agentId = null, options = {}) => {
  const { autoConnect = true } = options;
  const [agentStatuses, setAgentStatuses] = useState({});
  const [agentTasks, setAgentTasks] = useState({});

  const webSocket = useWebSocket({
    autoConnect,
    services: ['a2a'],
    onMessage: (service, eventType, data) => {
      if (eventType === 'agent_status') {
        if (!agentId || data.agent_id === agentId) {
          setAgentStatuses(prev => ({
            ...prev,
            [data.agent_id]: { ...data, timestamp: new Date() }
          }));
        }
      } else if (eventType === 'task_update') {
        if (!agentId || data.assigned_agents?.includes(agentId)) {
          setAgentTasks(prev => ({
            ...prev,
            [data.task_id]: { ...data, timestamp: new Date() }
          }));
        }
      }
    }
  });

  return {
    ...webSocket,
    agentStatuses,
    agentTasks,
    currentAgentStatus: agentId ? agentStatuses[agentId] : null,
    clearStatuses: () => {
      setAgentStatuses({});
      setAgentTasks({});
    }
  };
};

/**
 * Hook for Julia analysis monitoring
 */
export const useJuliaWebSocket = (analysisId = null, options = {}) => {
  const { autoConnect = true } = options;
  const [analysisProgress, setAnalysisProgress] = useState({});
  const [computationUpdates, setComputationUpdates] = useState({});

  const webSocket = useWebSocket({
    autoConnect,
    services: ['julia'],
    onMessage: (service, eventType, data) => {
      if (eventType === 'analysis_progress') {
        if (!analysisId || data.analysis_id === analysisId) {
          setAnalysisProgress(prev => ({
            ...prev,
            [data.analysis_id]: { ...data, timestamp: new Date() }
          }));
        }
      } else if (eventType === 'computation_update') {
        if (!analysisId || data.analysis_id === analysisId) {
          setComputationUpdates(prev => ({
            ...prev,
            [data.job_id]: { ...data, timestamp: new Date() }
          }));
        }
      }
    }
  });

  return {
    ...webSocket,
    analysisProgress,
    computationUpdates,
    currentProgress: analysisId ? analysisProgress[analysisId] : null,
    clearProgress: () => {
      setAnalysisProgress({});
      setComputationUpdates({});
    }
  };
};

export default useWebSocket;
