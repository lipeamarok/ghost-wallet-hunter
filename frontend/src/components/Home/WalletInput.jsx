import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { MagnifyingGlassIcon } from '@heroicons/react/24/outline';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import ExampleAddress from './ExampleAddress';

// Clean Architecture Integration
import { useInvestigation } from '../../hooks/useInvestigation.js';
import { validateWalletAddress, BLOCKCHAIN_NETWORKS } from '../../utils/validation.js';
import { formatWalletAddress } from '../../utils/formatters.js';

// Transition Components
import PageTransition from '../Transitions/PageTransition.jsx';
import BlockchainTravel from '../Loading/BlockchainTravel.jsx';

export default function WalletInput() {
  const [inputValue, setInputValue] = useState('');
  const [isInvestigating, setIsInvestigating] = useState(false);
  const navigate = useNavigate();

  // Using clean architecture hooks
  const {
    startInvestigation,
    isLoading: isAnalyzing,
    error: investigationError
  } = useInvestigation({
    autoConnect: false, // Don't auto-connect WebSockets
    pollingInterval: null // Don't poll for status updates
  });

  const handleAnalyze = async () => {
    if (!inputValue.trim()) {
      toast.error('Please enter a wallet address');
      return;
    }

    // Use new validation system (supports multiple chains)
    const validation = validateWalletAddress(inputValue.trim());

    if (!validation.isValid) {
      // Maintain original Solana-focused error message for UX consistency
      if (validation.error.includes('Unrecognized')) {
        toast.error('Invalid Solana wallet address format');
      } else {
        toast.error(validation.error);
      }
      return;
    }

    try {
      // Start investigation loading state
      setIsInvestigating(true);

      // Use investigation hook
      toast.loading('🕵️ Starting REAL investigation...', { duration: 3000 });

      const investigationResult = await startInvestigation({
        walletAddress: inputValue.trim(),
        investigationType: 'comprehensive',
        priority: 'medium',
        options: {
          realTimeUpdates: true,
          includeMetadata: true
        }
      });

      // Check for investigation ID using multiple possible field names
      const investigationId = investigationResult?.investigation_id ||
                             investigationResult?.investigationId ||
                             investigationResult?.id;

      if (investigationId) {
        toast.success('✅ Investigation started! Redirecting...', { duration: 2000 });

        // Add a small delay before navigation to show the loading state
        setTimeout(() => {
          // Navigate to investigation page with ID in URL and data in state
          navigate(`/investigation/${investigationId}`, {
            state: {
              walletAddress: inputValue.trim(),
              investigationData: {
                ...investigationResult,
                id: investigationId // Ensure consistent ID field
              },
              realTimeMode: true
            }
          });
        }, 1000);
      } else {
        console.error('🚨 No investigation ID found in response:', investigationResult);
        throw new Error('No investigation ID returned from backend');
      }

    } catch (error) {
      console.error('Investigation failed:', error);
      toast.error('Failed to start investigation. Please try again.');
      setIsInvestigating(false);

      // Maintain same fallback behavior for UX consistency
      setTimeout(() => {
        navigate('/investigation', {
          state: {
            walletAddress: inputValue.trim(),
            fallbackMode: true
          }
        });
      }, 1000);
    }
  };

  const handleExampleSelect = (address) => {
    setInputValue(address);
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 1.0, duration: 0.8 }}
      className="w-full max-w-2xl mx-auto space-y-4"
    >
      {/* Caixa de Input */}
      <div className="bg-white/5 backdrop-blur-lg border border-white/10 rounded-xl p-6 shadow-2xl">
        <div className="flex flex-col sm:flex-row gap-3">
          {/* Input Field */}
          <div className="flex-1">
            <input
              type="text"
              placeholder="Enter wallet address to investigate..."
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleAnalyze()}
              className="w-full px-4 py-3 text-base bg-white/10 border border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-accent focus:border-transparent transition-all duration-300 placeholder-gray-400"
            />
          </div>

          {/* Investigate Button */}
          <div className="flex gap-2">
            <motion.button
              onClick={handleAnalyze}
              disabled={isAnalyzing}
              className="px-6 py-3 bg-gradient-to-r from-blue-accent to-green-safe text-white font-semibold rounded-lg flex items-center justify-center space-x-2 shadow-lg disabled:opacity-50 disabled:cursor-not-allowed hover:shadow-xl transition-all duration-300 min-w-[140px]"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              transition={{ duration: 0.2 }}
            >
              {isAnalyzing ? (
                <>
                  <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span className="hidden sm:inline">Starting...</span>
                </>
              ) : (
                <>
                  <MagnifyingGlassIcon className="w-5 h-5" />
                  <span className="hidden sm:inline">Investigate</span>
                </>
              )}
            </motion.button>
          </div>
        </div>
      </div>

      {/* Exemplo abaixo da caixa */}
      <div className="text-center">
        <ExampleAddress onAddressSelect={handleExampleSelect} />
      </div>

      {/* Investigation Loading States */}
      <PageTransition show={isInvestigating} />
      {isInvestigating && <BlockchainTravel />}
    </motion.div>
  );
}
