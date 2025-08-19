/**
 * Ghost Wallet Hunter - Hooks Index
 * =================================
 *
 * Centralized export for all React hooks.
 * Provides unified access to the entire hooks layer.
 */

// Core hooks
export {
  useAPI,
  useAPIQuery,
  useAPIMutation,
  useAPIParallel
} from './useAPI.js';

export {
  useInvestigation,
  useInvestigationStats
} from './useInvestigation.js';

export { useInvestigationResults } from './useInvestigationResults.js';

export {
  useWebSocket,
  useInvestigationWebSocket,
  useAgentWebSocket,
  useJuliaWebSocket,
  CONNECTION_STATES
} from './useWebSocket.js';

/**
 * Composite hook for complete investigation workflow
 */
export const useInvestigationWorkflow = (options = {}) => {
  const investigation = useInvestigation(options);
  const webSocket = useWebSocket({
    autoConnect: options.autoConnect !== false,
    services: ['backend', 'a2a', 'julia']
  });

  return {
    // Investigation state and actions
    ...investigation,

    // WebSocket connectivity
    webSocketConnected: webSocket.isAllConnected,
    connectionStates: webSocket.connectionStates,

    // Combined loading state
    isLoading: investigation.isStarting ||
               investigation.isLoadingStatus ||
               webSocket.isConnecting,

    // Enhanced start function with WebSocket setup
    startInvestigationWithRealTime: async (params) => {
      const result = await investigation.startInvestigation(params);

      if (result && !webSocket.isAllConnected) {
        await webSocket.connectAll();
      }

      return result;
    },

    // Connection management
    reconnectWebSockets: webSocket.connectAll,
    disconnectWebSockets: webSocket.disconnectAll
  };
};

/**
 * Hook for system-wide health monitoring
 */
export const useSystemHealth = (options = {}) => {
  const { pollingInterval = 30000 } = options;

  const webSocket = useWebSocket({
    autoConnect: true,
    services: ['system']
  });

  const { data: healthData, loading, error, execute } = useAPIQuery(
    async () => {
      // This would call a system health endpoint
      const health = await webSocket.healthCheck();
      return health;
    },
    [],
    {
      pollingInterval,
      immediate: true
    }
  );

  return {
    healthData,
    loading,
    error,
    checkHealth: execute,
    systemConnected: webSocket.systemConnected,
    overallHealth: healthData?.healthy || false
  };
};
