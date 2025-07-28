/**
 * useBlacklist Hook
 * React hook for managing wallet blacklist checks
 */

import { useState, useCallback } from 'react';
import { useMutation, useQuery } from 'react-query';
import toast from 'react-hot-toast';
import { blacklistService } from '../services/blacklistService';

export const useBlacklist = () => {
  const [checkedWallets, setCheckedWallets] = useState(new Set());

  // Single wallet check
  const singleCheckMutation = useMutation(
    (walletAddress) => blacklistService.checkWallet(walletAddress),
    {
      onSuccess: (data, walletAddress) => {
        setCheckedWallets(prev => new Set([...prev, walletAddress]));

        if (data.data.is_blacklisted) {
          toast.error(`🚨 Carteira blacklisted: ${walletAddress.slice(0, 8)}...`, {
            duration: 8000,
            icon: '⚠️'
          });
        }
      },
      onError: (error) => {
        console.error('Blacklist check error:', error);
        toast.error('Erro ao verificar blacklist');
      }
    }
  );

  // Multiple wallets check
  const multipleCheckMutation = useMutation(
    (walletAddresses) => blacklistService.checkMultipleWallets(walletAddresses),
    {
      onSuccess: (data, walletAddresses) => {
        setCheckedWallets(prev => new Set([...prev, ...walletAddresses]));

        const { blacklisted_found } = data.data;
        if (blacklisted_found > 0) {
          toast.error(`🚨 ${blacklisted_found} carteiras blacklisted encontradas!`, {
            duration: 10000,
            icon: '⚠️'
          });
        } else {
          toast.success(`✅ ${walletAddresses.length} carteiras verificadas - nenhuma blacklisted`);
        }
      },
      onError: (error) => {
        console.error('Multiple blacklist check error:', error);
        toast.error('Erro ao verificar blacklists múltiplas');
      }
    }
  );

  // Get blacklist stats
  const {
    data: stats,
    isLoading: statsLoading,
    refetch: refetchStats
  } = useQuery(
    ['blacklist-stats'],
    blacklistService.getStats,
    {
      staleTime: 5 * 60 * 1000, // 5 minutes
      onError: (error) => {
        console.error('Stats error:', error);
      }
    }
  );

  // Public functions
  const checkWallet = useCallback((walletAddress) => {
    if (!walletAddress || checkedWallets.has(walletAddress)) {
      return Promise.resolve(null);
    }
    return singleCheckMutation.mutateAsync(walletAddress);
  }, [singleCheckMutation, checkedWallets]);

  const checkMultipleWallets = useCallback((walletAddresses) => {
    const uncheckedWallets = walletAddresses.filter(addr => !checkedWallets.has(addr));
    if (uncheckedWallets.length === 0) {
      return Promise.resolve(null);
    }
    return multipleCheckMutation.mutateAsync(uncheckedWallets);
  }, [multipleCheckMutation, checkedWallets]);

  const forceUpdate = useCallback(async () => {
    try {
      toast.loading('🔄 Atualizando blacklist...', { id: 'blacklist-update' });
      await blacklistService.forceUpdate();
      await refetchStats();
      toast.success('✅ Blacklist atualizada!', { id: 'blacklist-update' });
    } catch (error) {
      console.error('Force update error:', error);
      toast.error('❌ Erro ao atualizar blacklist', { id: 'blacklist-update' });
    }
  }, [refetchStats]);

  const searchBlacklist = useCallback(async (query) => {
    try {
      const result = await blacklistService.searchBlacklist(query);
      return result.data;
    } catch (error) {
      console.error('Search error:', error);
      toast.error('Erro na busca');
      throw error;
    }
  }, []);

  return {
    // Actions
    checkWallet,
    checkMultipleWallets,
    forceUpdate,
    searchBlacklist,

    // State
    isChecking: singleCheckMutation.isLoading || multipleCheckMutation.isLoading,
    checkedWallets,
    stats: stats?.data,
    statsLoading,

    // Utilities
    hasBeenChecked: (walletAddress) => checkedWallets.has(walletAddress),
    clearChecked: () => setCheckedWallets(new Set())
  };
};

export default useBlacklist;
