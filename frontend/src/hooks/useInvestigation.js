/**
 * Ghost Wallet Hunter - useInvestigation Hook
 * ===========================================
 *
 * Specialized React hook for managing wallet investigations.
 * Handles investigation lifecycle, real-time updates, result consolidation,
 * and provides a comprehensive interface for investigation workflows.
 */

import { useState, useCallback, useEffect, useRef } from 'react';
import { useAPI, useAPIMutation, useAPIQuery } from './useAPI.js';
import { investigationService, webSocketService } from '../services/index.js';
import { INVESTIGATION_TYPES, INVESTIGATION_STATUS } from '../config/constants.js';
import { IS_DEVELOPMENT } from '../config/environment.js';

/**
 * Main investigation management hook
 * @param {Object} options - Configuration options
 * @param {boolean} options.autoConnect - Auto-connect to WebSocket updates
 * @param {number} options.pollingInterval - Status polling interval when WebSocket unavailable
 * @param {Function} options.onStatusChange - Callback for status changes
 * @param {Function} options.onComplete - Callback for investigation completion
 * @param {Function} options.onError - Callback for investigation errors
 */
export const useInvestigation = (options = {}) => {
  const {
    autoConnect = true,
    pollingInterval = 5000,
    onStatusChange,
    onComplete,
    onError
  } = options;

  // If pollingInterval is explicitly set to null, disable polling completely
  const shouldPoll = pollingInterval !== null && pollingInterval > 0;

  if (IS_DEVELOPMENT && pollingInterval === null) {
    console.log('🔄 Polling disabled for investigation hook (pollingInterval: null)');
  }

  // Investigation state
  const [currentInvestigation, setCurrentInvestigation] = useState(null);
  const [investigationHistory, setInvestigationHistory] = useState([]);
  const [realTimeUpdates, setRealTimeUpdates] = useState([]);
  const [webSocketConnected, setWebSocketConnected] = useState(false);

  // WebSocket subscription refs
  const unsubscribeRefs = useRef([]);

  // API hooks for investigation operations
  const startMutation = useAPIMutation(investigationService.startInvestigation, {
    onSuccess: (result) => {
      // Handle both possible field names from different backend responses
      const investigationId = result.investigation_id || result.investigationId || result.id;

      if (!investigationId) {
        console.error('🚨 No investigation ID found in response:', result);
        if (onError) onError(new Error('No investigation ID returned from backend'));
        return;
      }

      setCurrentInvestigation({
        id: investigationId,
        status: result.status || 'running',
        services: result.services || {},
        startTime: new Date(),
        progress: { overall: 0 },
        data: result // Store the full response
      });

      // Small delay to ensure investigation is properly registered before any status queries
      setTimeout(() => {
        if (autoConnect && investigationId) {
          connectToInvestigation(investigationId);
        }
      }, 100);

      if (IS_DEVELOPMENT) {
        console.log('✅ Investigation started:', investigationId);
      }
    },
    onError: (error) => {
      console.error('🚨 Investigation start failed:', error);
      if (onError) onError(error);
    }
  });

  const cancelMutation = useAPIMutation(investigationService.cancel, {
    onSuccess: () => {
      setCurrentInvestigation(prev => prev ? { ...prev, status: 'cancelled' } : null);
      disconnectFromInvestigation();
    }
  });

  // Status polling (fallback when WebSocket unavailable)
  const investigationId = currentInvestigation?.id;
  const isInvestigationActive = currentInvestigation &&
                               ['running', 'processing', 'analyzing'].includes(currentInvestigation.status);

  const shouldEnablePolling = Boolean(investigationId) &&
                             !webSocketConnected &&
                             shouldPoll &&
                             pollingInterval !== null && // Extra check to ensure polling is explicitly enabled
                             isInvestigationActive; // Only poll for active investigations

  if (IS_DEVELOPMENT && investigationId) {
    console.log('🔄 Status polling check:', {
      investigationId,
      shouldPoll,
      pollingInterval,
      isInvestigationActive,
      shouldEnablePolling,
      webSocketConnected
    });
  }

  const statusQuery = useAPIQuery(
    investigationService.getStatus,
    investigationId ? [investigationId] : [],
    {
      enabled: shouldEnablePolling && Boolean(investigationId), // Double check for investigation ID
      pollingInterval: shouldEnablePolling ? pollingInterval : null,
      onSuccess: (status) => {
        updateInvestigationStatus(status);
      },
      onError: (error) => {
        // Only log meaningful errors when polling is expected
        if (investigationId && shouldPoll) {
          console.error('🚨 Status polling failed for investigation:', investigationId, error);
        }
      }
    }
  );

  // Results fetching
  const resultsQuery = useAPI(investigationService.getResults);

  /**
   * Start a new investigation
   */
  const startInvestigation = useCallback(async (params) => {
    if (IS_DEVELOPMENT) {
      console.log('🔍 Starting investigation:', params);
    }

    // Validate required parameters
    if (!params.walletAddress) {
      throw new Error('Wallet address is required');
    }

    // Set default investigation type if not provided
    const investigationParams = {
      investigationType: INVESTIGATION_TYPES.COMPREHENSIVE,
      ...params
    };

    return startMutation.mutate(investigationParams);
  }, [startMutation]);

  /**
   * Cancel current investigation
   */
  const cancelInvestigation = useCallback(async () => {
    if (!currentInvestigation) {
      throw new Error('No active investigation to cancel');
    }

    return cancelMutation.mutate(currentInvestigation.id);
  }, [currentInvestigation, cancelMutation]);

  /**
   * Get investigation results
   */
  const getResults = useCallback(async (investigationId = null) => {
    const targetId = investigationId || currentInvestigation?.id;

    if (!targetId) {
      throw new Error('No investigation ID provided');
    }

    return resultsQuery.execute(targetId);
  }, [currentInvestigation, resultsQuery]);

  /**
   * Update investigation status from various sources
   */
  const updateInvestigationStatus = useCallback((statusUpdate) => {
    setCurrentInvestigation(prev => {
      if (!prev || prev.id !== statusUpdate.investigationId) {
        return prev;
      }

      const updated = {
        ...prev,
        status: statusUpdate.status,
        progress: statusUpdate.progress || prev.progress,
        services: statusUpdate.services || prev.services,
        lastUpdate: new Date()
      };

      // Trigger callbacks
      if (onStatusChange && prev.status !== statusUpdate.status) {
        onStatusChange(statusUpdate);
      }

      if (onComplete && statusUpdate.status === INVESTIGATION_STATUS.COMPLETED) {
        onComplete(statusUpdate);
      }

      return updated;
    });
  }, [onStatusChange, onComplete]);

  /**
   * Connect to real-time investigation updates
   */
  const connectToInvestigation = useCallback(async (investigationId) => {
    try {
      // Connect to WebSocket services
      await webSocketService.connectAll();
      setWebSocketConnected(true);

      // Subscribe to investigation updates
      const unsubscribeInvestigation = webSocketService.investigations
        .subscribeToInvestigationUpdates(investigationId, (update) => {
          if (IS_DEVELOPMENT) {
            console.log('📡 Investigation update:', update);
          }

          updateInvestigationStatus(update);
          setRealTimeUpdates(prev => [...prev, { ...update, timestamp: new Date() }]);
        });

      // Subscribe to agent updates
      const unsubscribeAgents = webSocketService.agents
        .subscribeToAgentStatus('*', (update) => {
          if (update.investigation_id === investigationId) {
            setRealTimeUpdates(prev => [...prev, {
              type: 'agent_update',
              ...update,
              timestamp: new Date()
            }]);
          }
        });

      // Subscribe to Julia analysis updates
      const unsubscribeJulia = webSocketService.julia
        .subscribeToAnalysisProgress('*', (update) => {
          if (update.investigation_id === investigationId) {
            setRealTimeUpdates(prev => [...prev, {
              type: 'julia_update',
              ...update,
              timestamp: new Date()
            }]);
          }
        });

      // Store unsubscribe functions
      unsubscribeRefs.current = [
        unsubscribeInvestigation,
        unsubscribeAgents,
        unsubscribeJulia
      ];

    } catch (error) {
      console.warn('⚠️ WebSocket connection failed, falling back to polling:', error);
      setWebSocketConnected(false);
    }
  }, [updateInvestigationStatus]);

  /**
   * Disconnect from real-time updates
   */
  const disconnectFromInvestigation = useCallback(() => {
    // Unsubscribe from all WebSocket updates
    unsubscribeRefs.current.forEach(unsubscribe => {
      if (typeof unsubscribe === 'function') {
        unsubscribe();
      }
    });
    unsubscribeRefs.current = [];
    setWebSocketConnected(false);
  }, []);

  /**
   * Load investigation history
   */
  const loadHistory = useCallback(async () => {
    try {
      const history = investigationService.getHistory();
      setInvestigationHistory(history);
      return history;
    } catch (error) {
      console.error('Failed to load investigation history:', error);
      throw error;
    }
  }, []);

  /**
   * Get active investigations
   */
  const getActiveInvestigations = useCallback(() => {
    return investigationService.getActive();
  }, []);

  // Cleanup effect
  useEffect(() => {
    return () => {
      disconnectFromInvestigation();
    };
  }, [disconnectFromInvestigation]);

  // Auto-load history on mount
  useEffect(() => {
    loadHistory();
  }, [loadHistory]);

  return {
    // Current investigation state
    currentInvestigation,
    investigationHistory,
    realTimeUpdates,
    webSocketConnected,

    // Investigation actions
    startInvestigation,
    cancelInvestigation,
    getResults,
    loadHistory,
    getActiveInvestigations,

    // Connection management
    connectToInvestigation,
    disconnectFromInvestigation,

    // Loading states
    isStarting: startMutation.isLoading,
    isCancelling: cancelMutation.isLoading,
    isLoadingStatus: statusQuery.loading,
    isLoadingResults: resultsQuery.loading,

    // Error states
    startError: startMutation.error,
    cancelError: cancelMutation.error,
    statusError: statusQuery.error,
    resultsError: resultsQuery.error,

    // Computed states
    hasActiveInvestigation: !!currentInvestigation,
    isInvestigationRunning: currentInvestigation?.status === INVESTIGATION_STATUS.RUNNING,
    isInvestigationCompleted: currentInvestigation?.status === INVESTIGATION_STATUS.COMPLETED,
    isInvestigationFailed: currentInvestigation?.status === INVESTIGATION_STATUS.FAILED,

    // Progress information
    overallProgress: currentInvestigation?.progress?.overall || 0,
    serviceProgress: currentInvestigation?.progress || {},

    // Service status
    serviceStatus: currentInvestigation?.services || {},

    // Recent updates
    recentUpdates: realTimeUpdates.slice(-10), // Last 10 updates

    // Utility functions
    clearUpdates: () => setRealTimeUpdates([]),
    clearHistory: () => setInvestigationHistory([])
  };
};

/**
 * Hook for investigation results with caching and formatting
 */
export const useInvestigationResults = (investigationId, options = {}) => {
  const {
    autoRefresh = false,
    refreshInterval = 30000,
    formatResults = true
  } = options;

  const resultsQuery = useAPIQuery(
    investigationService.getResults,
    investigationId ? [investigationId] : [],
    {
      enabled: !!investigationId,
      pollingInterval: autoRefresh ? refreshInterval : null,
      cacheTime: 10 * 60 * 1000 // 10 minutes cache
    }
  );

  // Format results for display
  const formattedResults = resultsQuery.data && formatResults
    ? formatInvestigationResults(resultsQuery.data)
    : resultsQuery.data;

  return {
    ...resultsQuery,
    results: formattedResults,
    rawResults: resultsQuery.data
  };
};

/**
 * Hook for investigation statistics and analytics
 */
export const useInvestigationStats = () => {
  const [stats, setStats] = useState({
    total: 0,
    completed: 0,
    running: 0,
    failed: 0,
    averageDuration: 0,
    successRate: 0
  });

  const calculateStats = useCallback((investigations) => {
    const total = investigations.length;
    const completed = investigations.filter(inv => inv.status === INVESTIGATION_STATUS.COMPLETED).length;
    const running = investigations.filter(inv => inv.status === INVESTIGATION_STATUS.RUNNING).length;
    const failed = investigations.filter(inv => inv.status === INVESTIGATION_STATUS.FAILED).length;

    const completedInvestigations = investigations.filter(inv =>
      inv.status === INVESTIGATION_STATUS.COMPLETED && inv.duration
    );

    const averageDuration = completedInvestigations.length > 0
      ? completedInvestigations.reduce((sum, inv) => sum + inv.duration, 0) / completedInvestigations.length
      : 0;

    const successRate = total > 0 ? (completed / total) * 100 : 0;

    return {
      total,
      completed,
      running,
      failed,
      averageDuration,
      successRate
    };
  }, []);

  const updateStats = useCallback((investigations) => {
    const newStats = calculateStats(investigations);
    setStats(newStats);
  }, [calculateStats]);

  return {
    stats,
    updateStats,
    calculateStats
  };
};

/**
 * Helper function to format investigation results for display
 */
const formatInvestigationResults = (results) => {
  if (!results) return null;

  return {
    ...results,
    summary: {
      ...results.summary,
      riskLevel: getRiskLevel(results.summary.riskScore),
      confidenceLevel: getConfidenceLevel(results.summary.confidence),
      formattedFlags: results.summary.flaggedActivities?.map(flag => ({
        ...flag,
        severityLevel: getSeverityLevel(flag.severity),
        icon: getFlagIcon(flag.type)
      })) || []
    },
    metadata: {
      ...results.metadata,
      formattedDuration: formatDuration(results.metadata.duration),
      completionTime: new Date(results.timestamp).toLocaleString()
    }
  };
};

/**
 * Helper functions for result formatting
 */
const getRiskLevel = (score) => {
  if (score >= 80) return 'High';
  if (score >= 50) return 'Medium';
  if (score >= 20) return 'Low';
  return 'Very Low';
};

const getConfidenceLevel = (confidence) => {
  if (confidence >= 90) return 'Very High';
  if (confidence >= 70) return 'High';
  if (confidence >= 50) return 'Medium';
  return 'Low';
};

const getSeverityLevel = (severity) => {
  if (severity >= 8) return 'Critical';
  if (severity >= 6) return 'High';
  if (severity >= 4) return 'Medium';
  return 'Low';
};

const getFlagIcon = (type) => {
  const iconMap = {
    'fraud': '🚨',
    'money_laundering': '💰',
    'suspicious_pattern': '🔍',
    'high_risk_transaction': '⚠️',
    'blacklisted_address': '🚫',
    'compliance_violation': '📋'
  };
  return iconMap[type] || '❓';
};

const formatDuration = (milliseconds) => {
  const seconds = Math.floor(milliseconds / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);

  if (hours > 0) {
    return `${hours}h ${minutes % 60}m`;
  } else if (minutes > 0) {
    return `${minutes}m ${seconds % 60}s`;
  } else {
    return `${seconds}s`;
  }
};

export default useInvestigation;
