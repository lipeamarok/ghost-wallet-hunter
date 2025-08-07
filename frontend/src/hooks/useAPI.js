/**
 * Ghost Wallet Hunter - useAPI Hook
 * =================================
 *
 * Generic React hook for API calls with loading states, error handling,
 * caching, and automatic retry logic. Provides a consistent interface
 * for all API interactions throughout the application.
 */

import { useState, useEffect, useRef, useCallback } from 'react';
import { IS_DEVELOPMENT } from '../config/environment.js';

/**
 * Custom hook for API calls with comprehensive state management
 * @param {Function} apiFunction - The API function to call
 * @param {Object} options - Configuration options
 * @param {boolean} options.immediate - Execute immediately on mount
 * @param {Array} options.dependencies - Dependencies to watch for re-execution
 * @param {number} options.cacheTime - Cache duration in milliseconds
 * @param {number} options.retryCount - Number of retry attempts
 * @param {number} options.retryDelay - Delay between retries
 * @param {Function} options.onSuccess - Success callback
 * @param {Function} options.onError - Error callback
 * @param {boolean} options.suspense - Enable suspense mode
 */
export const useAPI = (apiFunction, options = {}) => {
  const {
    immediate = false,
    dependencies = [],
    cacheTime = 5 * 60 * 1000, // 5 minutes default
    retryCount = 3,
    retryDelay = 1000,
    onSuccess,
    onError,
    suspense = false
  } = options;

  // State management
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [lastFetch, setLastFetch] = useState(null);
  const [retryAttempt, setRetryAttempt] = useState(0);

  // Refs for cleanup and consistency
  const abortControllerRef = useRef(null);
  const cacheRef = useRef(new Map());
  const timeoutRef = useRef(null);

  /**
   * Generate cache key from function and parameters
   */
  const generateCacheKey = useCallback((fn, params) => {
    const fnName = fn.name || 'anonymous';
    const paramsStr = JSON.stringify(params || {});
    return `${fnName}_${paramsStr}`;
  }, []);

  /**
   * Check if cached data is still valid
   */
  const isCacheValid = useCallback((cacheEntry) => {
    if (!cacheEntry) return false;
    return Date.now() - cacheEntry.timestamp < cacheTime;
  }, [cacheTime]);

  /**
   * Execute API call with retry logic
   */
  const executeAPI = useCallback(async (...params) => {
    // Cancel previous request if still pending
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    // Create new abort controller
    abortControllerRef.current = new AbortController();
    const { signal } = abortControllerRef.current;

    // Check cache first
    const cacheKey = generateCacheKey(apiFunction, params);
    const cachedData = cacheRef.current.get(cacheKey);

    if (isCacheValid(cachedData)) {
      if (IS_DEVELOPMENT) {
        console.log('📦 Using cached data for:', cacheKey);
      }
      setData(cachedData.data);
      setError(null);
      setLastFetch(new Date(cachedData.timestamp));
      return cachedData.data;
    }

    setLoading(true);
    setError(null);
    setRetryAttempt(0);

    const attemptRequest = async (attempt = 0) => {
      try {
        if (signal.aborted) {
          throw new Error('Request aborted');
        }

        if (IS_DEVELOPMENT) {
          console.log(`🔄 API Request (attempt ${attempt + 1}):`, apiFunction.name, params);
        }

        const result = await apiFunction(...params);

        if (signal.aborted) {
          throw new Error('Request aborted');
        }

        // Cache successful result
        cacheRef.current.set(cacheKey, {
          data: result,
          timestamp: Date.now()
        });

        setData(result);
        setError(null);
        setLastFetch(new Date());
        setRetryAttempt(0);

        // Call success callback
        if (onSuccess) {
          onSuccess(result);
        }

        if (IS_DEVELOPMENT) {
          console.log('✅ API Success:', apiFunction.name, result);
        }

        return result;

      } catch (err) {
        if (signal.aborted) {
          return; // Don't handle aborted requests
        }

        if (attempt < retryCount && !err.code?.includes('VALIDATION')) {
          // Retry for non-validation errors
          setRetryAttempt(attempt + 1);

          if (IS_DEVELOPMENT) {
            console.warn(`⚠️ API Error (retrying in ${retryDelay}ms):`, err.message);
          }

          return new Promise((resolve) => {
            timeoutRef.current = setTimeout(() => {
              resolve(attemptRequest(attempt + 1));
            }, retryDelay * Math.pow(2, attempt)); // Exponential backoff
          });
        } else {
          // Final error
          setError(err);
          setRetryAttempt(0);

          // Call error callback
          if (onError) {
            onError(err);
          }

          if (IS_DEVELOPMENT) {
            console.error('🚨 API Final Error:', apiFunction.name, err);
          }

          if (suspense) {
            throw err; // Re-throw for suspense error boundaries
          }
        }
      }
    };

    try {
      return await attemptRequest();
    } finally {
      setLoading(false);
    }
  }, [apiFunction, generateCacheKey, isCacheValid, retryCount, retryDelay, onSuccess, onError, suspense]);

  /**
   * Manual refresh function
   */
  const refresh = useCallback((...params) => {
    const cacheKey = generateCacheKey(apiFunction, params);
    cacheRef.current.delete(cacheKey); // Clear cache
    return executeAPI(...params);
  }, [executeAPI, generateCacheKey, apiFunction]);

  /**
   * Reset function to clear state
   */
  const reset = useCallback(() => {
    setData(null);
    setError(null);
    setLoading(false);
    setRetryAttempt(0);
    setLastFetch(null);

    // Cancel ongoing request
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    // Clear timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
  }, []);

  /**
   * Clear cache function
   */
  const clearCache = useCallback((specific = null) => {
    if (specific) {
      const cacheKey = generateCacheKey(apiFunction, specific);
      cacheRef.current.delete(cacheKey);
    } else {
      cacheRef.current.clear();
    }
  }, [generateCacheKey, apiFunction]);

  // Effect for immediate execution
  useEffect(() => {
    if (immediate) {
      executeAPI();
    }
  }, [immediate, executeAPI]);

  // Effect for dependency-based execution
  useEffect(() => {
    if (dependencies.length > 0 && !immediate) {
      executeAPI();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, dependencies);

  // Cleanup effect
  useEffect(() => {
    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, []);

  return {
    // Data and state
    data,
    loading,
    error,
    lastFetch,
    retryAttempt,

    // Actions
    execute: executeAPI,
    refresh,
    reset,
    clearCache,

    // Computed states
    isIdle: !loading && !error && !data,
    isSuccess: !loading && !error && data !== null,
    isError: !loading && error !== null,
    isRetrying: retryAttempt > 0,

    // Cache info
    isCached: data !== null && lastFetch !== null,
    cacheAge: lastFetch ? Date.now() - lastFetch.getTime() : null
  };
};

/**
 * Specialized hook for GET requests with automatic polling
 */
export const useAPIQuery = (apiFunction, params = [], options = {}) => {
  const {
    pollingInterval,
    enabled = true,
    ...restOptions
  } = options;

  // Ensure params is always an array and normalize dependencies
  const normalizedParams = Array.isArray(params) ? params : [params];
  const dependencyKey = JSON.stringify([enabled, ...normalizedParams]);

  const apiHook = useAPI(apiFunction, {
    immediate: enabled,
    dependencies: enabled ? [dependencyKey] : [], // Only pass dependencies if enabled
    ...restOptions
  });

  // Polling effect
  useEffect(() => {
    if (!pollingInterval || !enabled || apiHook.loading) {
      return;
    }

    const interval = setInterval(() => {
      apiHook.execute(...normalizedParams);
    }, pollingInterval);

    return () => clearInterval(interval);
  }, [pollingInterval, enabled, apiHook.loading, apiHook.execute, dependencyKey]);

  return apiHook;
};

/**
 * Hook for mutations (POST, PUT, DELETE operations)
 */
export const useAPIMutation = (apiFunction, options = {}) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [data, setData] = useState(null);

  const mutate = useCallback(async (...params) => {
    setIsLoading(true);
    setError(null);

    try {
      if (IS_DEVELOPMENT) {
        console.log('🔄 API Mutation:', apiFunction.name, params);
      }

      const result = await apiFunction(...params);

      setData(result);

      if (options.onSuccess) {
        options.onSuccess(result);
      }

      if (IS_DEVELOPMENT) {
        console.log('✅ Mutation Success:', apiFunction.name, result);
      }

      return result;
    } catch (err) {
      setError(err);

      if (options.onError) {
        options.onError(err);
      }

      if (IS_DEVELOPMENT) {
        console.error('🚨 Mutation Error:', apiFunction.name, err);
      }

      throw err;
    } finally {
      setIsLoading(false);
    }
  }, [apiFunction, options]);

  const reset = useCallback(() => {
    setData(null);
    setError(null);
    setIsLoading(false);
  }, []);

  return {
    mutate,
    data,
    error,
    isLoading,
    isSuccess: !isLoading && !error && data !== null,
    isError: !isLoading && error !== null,
    reset
  };
};

/**
 * Hook for parallel API calls
 */
export const useAPIParallel = (apiCalls, options = {}) => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState([]);
  const [progress, setProgress] = useState(0);

  const execute = useCallback(async () => {
    setLoading(true);
    setErrors([]);
    setProgress(0);

    try {
      const promises = apiCalls.map(async (call, index) => {
        try {
          const result = await call.fn(...(call.params || []));
          setProgress(prev => prev + (100 / apiCalls.length));
          return { success: true, data: result, index };
        } catch (error) {
          return { success: false, error, index };
        }
      });

      const results = await Promise.all(promises);

      const successData = [];
      const errorList = [];

      results.forEach(result => {
        if (result.success) {
          successData[result.index] = result.data;
        } else {
          errorList[result.index] = result.error;
        }
      });

      setData(successData);
      setErrors(errorList);

      if (options.onComplete) {
        options.onComplete(successData, errorList);
      }

      return successData;
    } finally {
      setLoading(false);
    }
  }, [apiCalls, options]);

  return {
    data,
    errors,
    loading,
    progress,
    execute,
    hasErrors: errors.some(error => error !== undefined),
    allSuccess: errors.every(error => error === undefined)
  };
};

export default useAPI;
