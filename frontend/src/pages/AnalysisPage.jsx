import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { MagnifyingGlassIcon, ExclamationTriangleIcon } from '@heroicons/react/24/outline';
import { useNavigate } from 'react-router-dom';
import { useWalletInvestigation } from '../hooks/useDetectiveAPI';

const AnalysisPage = () => {
  const [walletAddress, setWalletAddress] = useState('');
  const navigate = useNavigate();
  const { launchInvestigation, isInvestigating, error, result } = useWalletInvestigation();

  const handleAnalysis = async (e) => {
    e.preventDefault();

    if (!walletAddress.trim()) {
      alert('Please enter a wallet address');
      return;
    }

    try {
      launchInvestigation(walletAddress);

      // Navigate to results page with the investigation data
      if (result) {
        navigate('/results', {
          state: {
            investigationData: result,
            walletAddress: walletAddress
          }
        });
      }
    } catch (error) {
      console.error('Investigation error:', error);
      alert('An error occurred during the investigation. Please try again.');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-gray-900 py-12">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="text-center mb-12"
        >
          <h1 className="text-4xl sm:text-5xl font-bold text-white mb-6">
            Wallet Analysis
          </h1>
          <p className="text-xl text-gray-300 max-w-2xl mx-auto">
            Deploy our legendary detective squad to investigate any wallet address
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="bg-gray-800/50 backdrop-blur-sm rounded-2xl p-8 border border-purple-500/20"
        >
          <form onSubmit={handleAnalysis} className="space-y-6">
            <div>
              <label htmlFor="wallet" className="block text-sm font-medium text-gray-300 mb-3">
                Wallet Address
              </label>
              <div className="relative">
                <input
                  type="text"
                  id="wallet"
                  value={walletAddress}
                  onChange={(e) => setWalletAddress(e.target.value)}
                  placeholder="Enter wallet address (e.g., 0x742d35Cc6C6C4532C722C89a8A6020fD0A3c3c07)"
                  className="w-full px-4 py-4 bg-gray-900/50 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                  disabled={isInvestigating}
                />
                <MagnifyingGlassIcon className="absolute right-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              </div>
            </div>

            <div className="bg-yellow-900/20 border border-yellow-500/30 rounded-lg p-4">
              <div className="flex items-start">
                <ExclamationTriangleIcon className="w-5 h-5 text-yellow-400 mt-0.5 mr-3 flex-shrink-0" />
                <div className="text-sm text-yellow-300">
                  <p className="font-medium mb-1">Investigation Notice</p>
                  <p>
                    Our AI detective squad will analyze the provided wallet address using advanced blockchain forensics.
                    This may take a few moments and will consume AI credits.
                  </p>
                </div>
              </div>
            </div>

            <motion.button
              type="submit"
              disabled={isInvestigating || !walletAddress.trim()}
              whileHover={{ scale: isInvestigating ? 1 : 1.02 }}
              whileTap={{ scale: isInvestigating ? 1 : 0.98 }}
              className="w-full py-4 px-6 bg-gradient-to-r from-purple-600 to-blue-600 text-white font-semibold rounded-lg shadow-lg disabled:opacity-50 disabled:cursor-not-allowed hover:from-purple-700 hover:to-blue-700 transition-all"
            >
              {isInvestigating ? (
                <div className="flex items-center justify-center">
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-3"></div>
                  Investigating...
                </div>
              ) : (
                <div className="flex items-center justify-center">
                  <MagnifyingGlassIcon className="w-5 h-5 mr-2" />
                  Launch Investigation
                </div>
              )}
            </motion.button>
          </form>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.4 }}
          className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6"
        >
          <div className="bg-gray-800/30 backdrop-blur-sm rounded-xl p-6 border border-gray-700/50">
            <h3 className="text-lg font-semibold text-white mb-3">Deep Analysis</h3>
            <p className="text-gray-300 text-sm">
              Our AI detectives perform comprehensive blockchain analysis including transaction patterns, risk assessment, and behavioral analysis.
            </p>
          </div>

          <div className="bg-gray-800/30 backdrop-blur-sm rounded-xl p-6 border border-gray-700/50">
            <h3 className="text-lg font-semibold text-white mb-3">Multi-Detective Squad</h3>
            <p className="text-gray-300 text-sm">
              Seven specialized AI detectives work together, each bringing unique expertise to provide comprehensive insights.
            </p>
          </div>

          <div className="bg-gray-800/30 backdrop-blur-sm rounded-xl p-6 border border-gray-700/50">
            <h3 className="text-lg font-semibold text-white mb-3">Real-time Results</h3>
            <p className="text-gray-300 text-sm">
              Get instant insights with detailed reports, risk scores, and actionable intelligence about the investigated wallet.
            </p>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default AnalysisPage;
