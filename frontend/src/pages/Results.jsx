// src/pages/Results.jsx
import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import ThreeBackground from '../components/Background/ThreeBackground';

export default function Results() {
  const location = useLocation();
  const navigate = useNavigate();
  const { walletAddress, investigationData, investigationError, fallbackMode } = location.state || {};

  if (!walletAddress) {
    return (
      <div className="min-h-screen bg-navy text-white relative overflow-hidden">
        <ThreeBackground />
        <div className="absolute inset-0 bg-navy/80 z-10" />
        <div className="relative z-20 flex flex-col items-center justify-center min-h-screen px-4">
          <h1 className="text-2xl font-bold text-red-400 mb-4">❌ No results found</h1>
          <button
            onClick={() => navigate('/')}
            className="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg"
          >
            Start New Investigation
          </button>
        </div>
      </div>
    );
  }

  // Extract data from investigation result
  const riskScore = investigationData?.risk_assessment || investigationData?.ai_analysis?.risk_score || 0;
  const confidence = investigationData?.confidence_score || investigationData?.confidence_level || 0;
  const status = investigationError ? 'Failed' : 'Completed';

  const getRiskColor = (score) => {
    if (score >= 70) return 'text-red-400';
    if (score >= 40) return 'text-yellow-400';
    return 'text-green-400';
  };

  const getRiskLabel = (score) => {
    if (score >= 70) return 'HIGH RISK';
    if (score >= 40) return 'MEDIUM RISK';
    return 'LOW RISK';
  };

  return (
    <div className="min-h-screen bg-navy text-white relative overflow-hidden">
      {/* Background */}
      <ThreeBackground />
      <div className="absolute inset-0 bg-navy/80 z-10" />

      {/* Content */}
      <div className="relative z-20 flex flex-col items-center justify-center min-h-screen px-4">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center space-y-8 max-w-2xl w-full"
        >
          {/* Title */}
          <motion.h1
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-4xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent"
          >
            🕵️ Investigation Results
          </motion.h1>

          {/* Wallet Address */}
          <div className="bg-black/50 backdrop-blur-md rounded-lg p-4 border border-blue-500/30">
            <p className="text-gray-300 text-sm mb-2">Wallet Address:</p>
            <p className="font-mono text-blue-300 break-all text-sm">{walletAddress}</p>
          </div>

          {/* Results Card */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="bg-black/50 backdrop-blur-md rounded-xl p-8 border border-gray-600/30 space-y-6"
          >
            {investigationError ? (
              // Error State
              <div className="text-center space-y-4">
                <div className="text-6xl">❌</div>
                <h2 className="text-2xl font-bold text-red-400">Investigation Failed</h2>
                <p className="text-gray-400">{investigationError}</p>
                <p className="text-sm text-gray-500">Using fallback analysis</p>
              </div>
            ) : (
              // Success State
              <div className="text-center space-y-6">
                {/* Risk Score */}
                <div className="space-y-2">
                  <div className="text-6xl font-bold">
                    <span className={getRiskColor(riskScore)}>
                      {Math.round(riskScore)}%
                    </span>
                  </div>
                  <div>
                    <p className={`text-xl font-semibold ${getRiskColor(riskScore)}`}>
                      {getRiskLabel(riskScore)}
                    </p>
                    <p className="text-gray-400 text-sm">
                      Confidence: {Math.round(confidence * 100)}%
                    </p>
                  </div>
                </div>

                {/* Status */}
                <div className="flex justify-center space-x-6 text-sm">
                  <div className="text-center">
                    <p className="text-gray-400">Status</p>
                    <p className="text-green-400 font-semibold">{status}</p>
                  </div>
                  <div className="text-center">
                    <p className="text-gray-400">Analysis Type</p>
                    <p className="text-blue-400 font-semibold">
                      {fallbackMode ? 'Basic' : 'AI Enhanced'}
                    </p>
                  </div>
                </div>

                {/* Additional Info */}
                {investigationData?.blockchain_data && (
                  <div className="grid grid-cols-2 gap-4 text-sm bg-gray-800/50 rounded-lg p-4">
                    <div className="text-center">
                      <p className="text-gray-400">Transactions</p>
                      <p className="text-white font-semibold">
                        {investigationData.blockchain_data.transaction_count || 0}
                      </p>
                    </div>
                    <div className="text-center">
                      <p className="text-gray-400">Balance</p>
                      <p className="text-white font-semibold">
                        {investigationData.blockchain_data.balance || 0} SOL
                      </p>
                    </div>
                  </div>
                )}
              </div>
            )}
          </motion.div>

          {/* Action Button */}
          <motion.button
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => navigate('/')}
            className="bg-gradient-to-r from-blue-500 to-purple-600 text-white font-semibold py-4 px-8 rounded-lg shadow-lg hover:shadow-xl transition-all duration-200"
          >
            � Investigate Another Wallet
          </motion.button>
        </motion.div>
      </div>
    </div>
  );
}
