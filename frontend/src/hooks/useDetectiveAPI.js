import { useState, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from 'react-query';
import toast from 'react-hot-toast';
import { detectiveService, costService } from '../services/detectiveAPI';

// Hook for detective squad management
export const useDetectiveSquad = () => {
  const queryClient = useQueryClient();

  const squadStatusQuery = useQuery(
    'detective-squad-status',
    detectiveService.getSquadStatus,
    {
      refetchInterval: 30000, // Refresh every 30 seconds
      staleTime: 10000, // Consider data stale after 10 seconds
      retry: 3, // Retry failed requests 3 times
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, 30000),
      onError: (error) => {
        console.warn('Squad status query error:', error.message);
        // Only show toast for connection errors, not timeouts
        if (error.code !== 'TIMEOUT_ERROR') {
          toast.error(`🚨 Squad connection failed: ${error.message}`);
        }
      }
    }
  );

  const availableDetectivesQuery = useQuery(
    'available-detectives',
    detectiveService.getAvailableDetectives,
    {
      refetchInterval: 60000, // Refresh every minute
      staleTime: 30000,
      retry: 2, // Retry failed requests 2 times
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, 30000),
      onError: (error) => {
        console.warn('Available detectives query error:', error.message);
        if (error.code !== 'TIMEOUT_ERROR') {
          toast.error(`🚨 Failed to load detectives: ${error.message}`);
        }
      }
    }
  );

  const testAIMutation = useMutation(
    detectiveService.testRealAI,
    {
      onSuccess: (data) => {
        toast.success('🤖 AI integration test successful!');
        return data;
      },
      onError: (error) => {
        toast.error(`🚨 AI test failed: ${error.message}`);
      }
    }
  );

  const refreshSquadStatus = useCallback(() => {
    queryClient.invalidateQueries('detective-squad-status');
    queryClient.invalidateQueries('available-detectives');
  }, [queryClient]);

  return {
    squadStatus: squadStatusQuery.data,
    isLoadingSquad: squadStatusQuery.isLoading,
    squadError: squadStatusQuery.error,
    availableDetectives: availableDetectivesQuery.data,
    isLoadingDetectives: availableDetectivesQuery.isLoading,
    detectivesError: availableDetectivesQuery.error,
    testAI: testAIMutation.mutate,
    isTestingAI: testAIMutation.isLoading,
    refreshSquadStatus,
    refetchSquad: squadStatusQuery.refetch,
    refetchDetectives: availableDetectivesQuery.refetch
  };
};

// Hook for wallet investigation
export const useWalletInvestigation = () => {
  const [investigationState, setInvestigationState] = useState({
    isInvestigating: false,
    currentStep: 0,
    progress: 0,
    error: null,
    result: null
  });

  const investigationMutation = useMutation(
    ({ walletAddress, options }) => detectiveService.launchInvestigation(walletAddress, options),
    {
      onMutate: () => {
        setInvestigationState(prev => ({
          ...prev,
          isInvestigating: true,
          error: null,
          progress: 0
        }));
        toast.loading('🕵️ Starting squad investigation...', { id: 'investigation' });
      },
      onSuccess: (data) => {
        setInvestigationState(prev => ({
          ...prev,
          isInvestigating: false,
          progress: 100,
          result: data
        }));
        toast.success('🎉 Investigation completed successfully!', { id: 'investigation' });
        return data;
      },
      onError: (error) => {
        let errorMessage = 'Investigation failed';
        let userFriendlyMessage = 'Please try again in a moment';

        if (error.code === 'TIMEOUT_ERROR') {
          errorMessage = 'Investigation timeout';
          userFriendlyMessage = 'The investigation is taking longer than expected. This may be due to complex analysis. Please try again.';
        } else if (error.code === 'CONNECTION_ERROR') {
          errorMessage = 'Connection failed';
          userFriendlyMessage = 'Unable to connect to the detective squad. Please check your internet connection.';
        } else if (error.code?.startsWith('HTTP_')) {
          errorMessage = 'Server error';
          userFriendlyMessage = 'The detective squad is temporarily unavailable. Please try again later.';
        }

        setInvestigationState(prev => ({
          ...prev,
          isInvestigating: false,
          error: `${errorMessage}: ${userFriendlyMessage}`
        }));
        toast.error(`🚨 ${errorMessage}: ${userFriendlyMessage}`, {
          id: 'investigation',
          duration: 6000
        });
      }
    }
  );

  const launchInvestigation = useCallback((walletAddress, options = {}) => {
    const defaultOptions = {
      depth: 2,
      includeMetadata: true,
      budget_limit: 5.0,
      user_id: 'frontend_user',
      ...options
    };

    return investigationMutation.mutateAsync({ walletAddress, options: defaultOptions });
  }, [investigationMutation]);

  const resetInvestigation = useCallback(() => {
    setInvestigationState({
      isInvestigating: false,
      currentStep: 0,
      progress: 0,
      error: null,
      result: null
    });
  }, []);

  return {
    ...investigationState,
    launchInvestigation,
    resetInvestigation,
    isLoading: investigationMutation.isLoading
  };
};

// Hook for individual detective analysis
export const useIndividualDetective = () => {
  const [activeDetective, setActiveDetective] = useState(null);

  const detectiveAnalysisMutation = useMutation(
    ({ detective, walletAddress }) => {
      const analysisFunction = detectiveService.detectiveAnalysis[detective.toLowerCase()];
      if (!analysisFunction) {
        throw new Error(`Detective ${detective} not found`);
      }
      return analysisFunction(walletAddress);
    },
    {
      onMutate: ({ detective }) => {
        setActiveDetective(detective);
        toast.loading(`🕵️ ${detective} is analyzing...`, { id: `detective-${detective}` });
      },
      onSuccess: (data, { detective }) => {
        setActiveDetective(null);
        toast.success(`✅ ${detective} analysis complete!`, { id: `detective-${detective}` });
        return data;
      },
      onError: (error, { detective }) => {
        setActiveDetective(null);
        toast.error(`🚨 ${detective} analysis failed: ${error.message}`, { id: `detective-${detective}` });
      }
    }
  );

  const analyzeWithDetective = useCallback((detective, walletAddress) => {
    detectiveAnalysisMutation.mutate({ detective, walletAddress });
  }, [detectiveAnalysisMutation]);

  return {
    analyzeWithDetective,
    activeDetective,
    isAnalyzing: detectiveAnalysisMutation.isLoading,
    analysisResult: detectiveAnalysisMutation.data,
    analysisError: detectiveAnalysisMutation.error
  };
};

// Hook for AI cost management
export const useAICostManagement = (userId = 'frontend_user') => {
  const queryClient = useQueryClient();

  const costDashboardQuery = useQuery(
    'ai-cost-dashboard',
    costService.getDashboard,
    {
      refetchInterval: 30000, // Refresh every 30 seconds
      staleTime: 10000,
    }
  );

  const userUsageQuery = useQuery(
    ['ai-user-usage', userId],
    () => costService.getUserUsage(userId),
    {
      refetchInterval: 10000, // Refresh every 10 seconds
      staleTime: 5000,
    }
  );

  const providersStatusQuery = useQuery(
    'ai-providers-status',
    costService.getProvidersStatus,
    {
      refetchInterval: 60000, // Refresh every minute
      staleTime: 30000,
    }
  );

  const updateLimitsMutation = useMutation(
    (limits) => costService.updateUserLimits(limits, userId),
    {
      onSuccess: () => {
        toast.success('💰 Cost limits updated successfully!');
        queryClient.invalidateQueries(['ai-user-usage', userId]);
      },
      onError: (error) => {
        toast.error(`🚨 Failed to update limits: ${error.message}`);
      }
    }
  );

  const refreshCostData = useCallback(() => {
    queryClient.invalidateQueries('ai-cost-dashboard');
    queryClient.invalidateQueries(['ai-user-usage', userId]);
    queryClient.invalidateQueries('ai-providers-status');
  }, [queryClient, userId]);

  return {
    dashboard: costDashboardQuery.data,
    userUsage: userUsageQuery.data,
    providersStatus: providersStatusQuery.data,
    isLoadingDashboard: costDashboardQuery.isLoading,
    isLoadingUsage: userUsageQuery.isLoading,
    isLoadingProviders: providersStatusQuery.isLoading,
    updateLimits: updateLimitsMutation.mutate,
    isUpdatingLimits: updateLimitsMutation.isLoading,
    refreshCostData,
    costError: costDashboardQuery.error || userUsageQuery.error || providersStatusQuery.error
  };
};

// Hook for real-time notifications
export const useRealTimeNotifications = () => {
  const [notifications, setNotifications] = useState([]);

  const addNotification = useCallback((notification) => {
    const id = Date.now().toString();
    const newNotification = {
      id,
      timestamp: new Date().toISOString(),
      read: false,
      ...notification
    };

    setNotifications(prev => [newNotification, ...prev.slice(0, 49)]); // Keep last 50

    // Auto-remove after 5 seconds for success messages
    if (notification.type === 'success') {
      setTimeout(() => {
        setNotifications(prev => prev.filter(n => n.id !== id));
      }, 5000);
    }

    return id;
  }, []);

  const markAsRead = useCallback((notificationId) => {
    setNotifications(prev => prev.map(n =>
      n.id === notificationId ? { ...n, read: true } : n
    ));
  }, []);

  const clearAll = useCallback(() => {
    setNotifications([]);
  }, []);

  const unreadCount = notifications.filter(n => !n.read).length;

  return {
    notifications,
    unreadCount,
    addNotification,
    markAsRead,
    clearAll
  };
};
