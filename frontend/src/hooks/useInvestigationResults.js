import { useState, useEffect } from 'react';
import { useAPIQuery } from './useAPI.js';
import { investigationService } from '../services/index.js';

/**
 * Investigation results hook - SIMPLIFIED for synchronous mode
 * Only uses initialData, no API calls until backend implements results endpoint
 */
export const useInvestigationResults = (investigationId, options = {}) => {
  const { autoRefresh = false, refreshInterval = 30000, formatResults = true, initialData = null } = options;
  const [localData, setLocalData] = useState(initialData);

  console.log(`🔍 useInvestigationResults SIMPLIFIED:`, {
    investigationId,
    hasInitialData: !!initialData,
    hasLocalData: !!localData,
    initialDataKeys: initialData ? Object.keys(initialData) : 'none'
  });

  // Set initial data immediately when available
  useEffect(() => {
    if (initialData && !localData) {
      console.log('🔍 Setting initial data from navigation:', initialData);
      setLocalData(initialData);
    }
  }, [initialData, localData]);

  return {
    results: localData,
    loading: false, // Never loading in synchronous mode
    error: null,    // No errors from API
    refresh: () => {
      console.log('🔍 Refresh not available in synchronous mode');
    }
  };
};

export default useInvestigationResults;