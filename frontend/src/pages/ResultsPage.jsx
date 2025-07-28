import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useQuery } from 'react-query';
import {
  ArrowLeftIcon,
  ShieldExclamationIcon,
  ShieldCheckIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon
} from '@heroicons/react/24/outline';

import LoadingSpinner from '../components/UI/LoadingSpinner';
import { quickAnalysis } from '../utils/api';

const ResultsPage = () => {
  const { walletAddress } = useParams();
  const navigate = useNavigate();

  // For demo purposes, we'll use quick analysis
  const { data, isLoading, error } = useQuery(
    ['quickAnalysis', walletAddress],
    () => quickAnalysis(walletAddress),
    {
      enabled: !!walletAddress,
      retry: 1,
    }
  );

  const getRiskColor = (riskLevel) => {
    switch (riskLevel?.toLowerCase()) {
      case 'low': return 'text-green-400';
      case 'medium': return 'text-yellow-400';
      case 'high': return 'text-red-400';
      default: return 'text-gray-400';
    }
  };

  const getRiskIcon = (riskLevel) => {
    switch (riskLevel?.toLowerCase()) {
      case 'low': return ShieldCheckIcon;
      case 'medium': return ExclamationTriangleIcon;
      case 'high': return ShieldExclamationIcon;
      default: return InformationCircleIcon;
    }
  };

  const getRiskBg = (riskLevel) => {
    switch (riskLevel?.toLowerCase()) {
      case 'low': return 'bg-green-500/20 border-green-500/30';
      case 'medium': return 'bg-yellow-500/20 border-yellow-500/30';
      case 'high': return 'bg-red-500/20 border-red-500/30';
      default: return 'bg-gray-500/20 border-gray-500/30';
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <LoadingSpinner size="large" />
          <p className="text-gray-300 mt-4">Loading analysis results...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center max-w-md">
          <div className="w-16 h-16 mx-auto mb-4 bg-red-500/20 rounded-full flex items-center justify-center">
            <ExclamationTriangleIcon className="w-8 h-8 text-red-400" />
          </div>
          <h2 className="text-2xl font-bold text-white mb-4">Failed to Load Results</h2>
          <p className="text-gray-300 mb-6">{error.message}</p>
          <button
            onClick={() => navigate('/')}
            className="px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
          >
            Start New Analysis
          </button>
        </div>
      </div>
    );
  }

  const RiskIcon = getRiskIcon(data?.risk_level);

  return (
    <div className="min-h-screen py-12">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8"
        >
          <button
            onClick={() => navigate('/')}
            className="flex items-center space-x-2 text-gray-400 hover:text-white transition-colors mb-6"
          >
            <ArrowLeftIcon className="w-5 h-5" />
            <span>New Analysis</span>
          </button>

          <h1 className="text-3xl font-bold text-white mb-4">Analysis Results</h1>
          <div className="bg-gray-800/50 rounded-lg p-4 border border-gray-700">
            <div className="text-sm text-gray-400 mb-1">Analyzed Wallet:</div>
            <div className="font-mono text-purple-400 break-all">{walletAddress}</div>
          </div>
        </motion.div>

        {/* Main Results Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Risk Assessment */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="lg:col-span-1"
          >
            <div className={`rounded-xl p-6 border ${getRiskBg(data?.risk_level)}`}>
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-bold text-white">Risk Assessment</h2>
                <RiskIcon className={`w-8 h-8 ${getRiskColor(data?.risk_level)}`} />
              </div>

              {/* Risk Score Circle */}
              <div className="text-center mb-6">
                <div className="relative w-32 h-32 mx-auto mb-4">
                  <svg className="w-32 h-32 transform -rotate-90" viewBox="0 0 100 100">
                    <circle
                      cx="50"
                      cy="50"
                      r="40"
                      stroke="currentColor"
                      strokeWidth="8"
                      fill="transparent"
                      className="text-gray-700"
                    />
                    <circle
                      cx="50"
                      cy="50"
                      r="40"
                      stroke="currentColor"
                      strokeWidth="8"
                      fill="transparent"
                      strokeDasharray={`${(data?.risk_score || 0) * 251.2} 251.2`}
                      className={getRiskColor(data?.risk_level)}
                    />
                  </svg>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <span className="text-2xl font-bold text-white">
                      {Math.round((data?.risk_score || 0) * 100)}%
                    </span>
                  </div>
                </div>

                <div className={`text-xl font-bold ${getRiskColor(data?.risk_level)} mb-2`}>
                  {data?.risk_level?.toUpperCase() || 'UNKNOWN'} RISK
                </div>

                <div className="text-sm text-gray-400">
                  Risk Score: {((data?.risk_score || 0) * 100).toFixed(1)}/100
                </div>
              </div>
            </div>
          </motion.div>

          {/* Stats Overview */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="lg:col-span-2"
          >
            <div className="bg-gray-800/50 rounded-xl p-6 border border-gray-700">
              <h2 className="text-xl font-bold text-white mb-6">Analysis Overview</h2>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                <div className="text-center p-4 bg-gray-700/30 rounded-lg">
                  <div className="text-2xl font-bold text-purple-400 mb-1">
                    {data?.cluster_count || 0}
                  </div>
                  <div className="text-sm text-gray-400">Wallet Clusters</div>
                </div>

                <div className="text-center p-4 bg-gray-700/30 rounded-lg">
                  <div className="text-2xl font-bold text-purple-400 mb-1">
                    {data?.total_connections || 0}
                  </div>
                  <div className="text-sm text-gray-400">Total Connections</div>
                </div>

                <div className="text-center p-4 bg-gray-700/30 rounded-lg">
                  <div className="text-2xl font-bold text-purple-400 mb-1">
                    {new Date(data?.analysis_timestamp || Date.now()).toLocaleDateString()}
                  </div>
                  <div className="text-sm text-gray-400">Analysis Date</div>
                </div>

                <div className="text-center p-4 bg-gray-700/30 rounded-lg">
                  <div className="text-2xl font-bold text-green-400 mb-1">
                    ✓ AI Enhanced
                  </div>
                  <div className="text-sm text-gray-400">JuliaOS Powered</div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Detailed Analysis */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="mt-8"
        >
          <div className="bg-gray-800/50 rounded-xl p-6 border border-gray-700">
            <h2 className="text-xl font-bold text-white mb-6">Detailed Analysis</h2>

            <div className="space-y-4">
              <div className="p-4 bg-gray-700/30 rounded-lg">
                <h3 className="font-semibold text-white mb-2">🤖 AI Analysis</h3>
                <p className="text-gray-300 text-sm">
                  This wallet has been analyzed using advanced AI algorithms powered by JuliaOS.
                  The analysis includes transaction pattern recognition, behavioral analysis, and
                  risk assessment based on multiple factors.
                </p>
              </div>

              <div className="p-4 bg-gray-700/30 rounded-lg">
                <h3 className="font-semibold text-white mb-2">🔗 Network Analysis</h3>
                <p className="text-gray-300 text-sm">
                  Connected wallets and transaction patterns have been mapped to identify
                  potential clustering behavior and fund flow relationships.
                </p>
              </div>

              <div className="p-4 bg-gray-700/30 rounded-lg">
                <h3 className="font-semibold text-white mb-2">⚡ Real-time Data</h3>
                <p className="text-gray-300 text-sm">
                  Analysis performed using live Solana blockchain data with up-to-date
                  transaction information and current wallet status.
                </p>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Actions */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="mt-8 text-center"
        >
          <div className="space-y-4 sm:space-y-0 sm:space-x-4 sm:flex sm:justify-center">
            <button
              onClick={() => navigate('/')}
              className="block w-full sm:w-auto px-8 py-3 bg-purple-600 text-white font-medium rounded-lg hover:bg-purple-700 transition-colors"
            >
              Analyze Another Wallet
            </button>

            <button
              onClick={() => {
                navigator.clipboard.writeText(window.location.href);
                toast.success('Results link copied to clipboard!');
              }}
              className="block w-full sm:w-auto px-8 py-3 bg-gray-600 text-white font-medium rounded-lg hover:bg-gray-700 transition-colors"
            >
              Share Results
            </button>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default ResultsPage;
