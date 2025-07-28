import React from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
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
  const location = useLocation();

  // Get investigation data from navigation state (priority)
  const navigationData = location.state?.investigationData;
  const walletFromState = location.state?.walletAddress;

  // Use navigation data if available, otherwise fallback to API query
  const { data: queryData, isLoading, error } = useQuery(
    ['quickAnalysis', walletAddress],
    () => quickAnalysis(walletAddress),
    {
      enabled: !!walletAddress && !navigationData, // Only query if no navigation data
      retry: 1,
    }
  );

  // Use navigation data as priority, fallback to query data
  const data = navigationData || queryData;
  const displayWallet = walletFromState || walletAddress;

  // Debug: Log the data structure
  console.log('🔍 DEBUG - Investigation Data:', {
    navigationData,
    queryData,
    finalData: data,
    walletFromState,
    walletAddress: displayWallet
  });

  const getRiskColor = (riskLevel) => {
    // Handle both demo format (risk_assessment.risk_level) and old format (risk_level)
    const level = riskLevel || data?.risk_assessment?.risk_level || data?.risk_level;
    switch (level?.toLowerCase()) {
      case 'low': return 'text-green-400';
      case 'medium': return 'text-yellow-400';
      case 'high': return 'text-red-400';
      default: return 'text-gray-400';
    }
  };

  const getRiskIcon = (riskLevel) => {
    const level = riskLevel || data?.risk_assessment?.risk_level || data?.risk_level;
    switch (level?.toLowerCase()) {
      case 'low': return ShieldCheckIcon;
      case 'medium': return ExclamationTriangleIcon;
      case 'high': return ShieldExclamationIcon;
      default: return InformationCircleIcon;
    }
  };

  const getRiskBg = (riskLevel) => {
    const level = riskLevel || data?.risk_assessment?.risk_level || data?.risk_level;
    switch (level?.toLowerCase()) {
      case 'low': return 'bg-green-500/20 border-green-500/30';
      case 'medium': return 'bg-yellow-500/20 border-yellow-500/30';
      case 'high': return 'bg-red-500/20 border-red-500/30';
      default: return 'bg-gray-500/20 border-gray-500/30';
    }
  };

  // Loading states
  if (isLoading && !navigationData) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <LoadingSpinner message="Loading analysis results..." />
      </div>
    );
  }

  // Error state
  if (error && !navigationData) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-white mb-4">Error Loading Results</h2>
          <p className="text-gray-400 mb-8">{error.message}</p>
          <button
            onClick={() => navigate('/')}
            className="px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
          >
            Return Home
          </button>
        </div>
      </div>
    );
  }

  // No data state
  if (!data) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-white mb-4">No Results Available</h2>
          <p className="text-gray-400 mb-8">Unable to load analysis data for this wallet.</p>
          <button
            onClick={() => navigate('/')}
            className="px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
          >
            Analyze Another Wallet
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8"
        >
          <button
            onClick={() => navigate('/')}
            className="flex items-center text-purple-400 hover:text-purple-300 mb-6 transition-colors"
          >
            <ArrowLeftIcon className="h-5 w-5 mr-2" />
            Back to Analysis
          </button>

          <h1 className="text-3xl font-bold text-white mb-4">
            Wallet Investigation Results
          </h1>

          <div className="bg-gray-800/50 rounded-lg p-4 border border-gray-700">
            <div className="text-sm text-gray-400 mb-1">Analyzed Wallet:</div>
            <div className="font-mono text-purple-400 break-all">{displayWallet}</div>
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
            <div className={`rounded-lg border p-6 ${getRiskBg()}`}>
              <div className="flex items-center mb-4">
                {React.createElement(getRiskIcon(), { className: `h-6 w-6 ${getRiskColor()} mr-3` })}
                <h3 className="text-xl font-semibold text-white">
                  Risk Assessment
                </h3>
              </div>
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-gray-300">Risk Level:</span>
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${getRiskColor()}`}>
                    {data?.risk_assessment?.risk_level || data?.risk_level || 'Unknown'}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-300">Confidence:</span>
                  <span className="text-white">
                    {data?.risk_assessment?.confidence || data?.confidence || 'N/A'}%
                  </span>
                </div>
                <div className="mt-4">
                  <p className="text-gray-300 text-sm mb-2">Summary:</p>
                  <p className="text-white">
                    {data?.risk_assessment?.summary || data?.risk_summary || 'No risk summary available.'}
                  </p>
                </div>
                {(data?.risk_assessment?.threats || data?.threats) && (
                  <div className="mt-4">
                    <p className="text-gray-300 text-sm mb-2">Key Threats:</p>
                    <ul className="list-disc list-inside text-white space-y-1">
                      {(data.risk_assessment?.threats || data.threats || []).map((threat, index) => (
                        <li key={index} className="text-sm">{threat}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            </div>
          </motion.div>

          {/* Detective Findings */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="lg:col-span-2"
          >
            <div className="bg-gray-800/50 rounded-lg p-6 border border-gray-700">
              <h3 className="text-xl font-semibold text-white mb-6">
                🕵️ Detective Findings
              </h3>
              
              <div className="space-y-4">
                {data?.findings?.map((finding, index) => (
                  <div key={index} className="p-4 bg-gray-700/30 rounded-lg">
                    <div className="flex items-start justify-between mb-2">
                      <h4 className="font-medium text-purple-400">
                        {finding.detective_name || `Detective ${index + 1}`}
                      </h4>
                      <span className="text-xs text-gray-400">
                        {finding.confidence || 'N/A'}% confidence
                      </span>
                    </div>
                    <p className="text-gray-300 text-sm mb-3">
                      {finding.analysis || finding.finding || 'No analysis available.'}
                    </p>
                    {finding.evidence && finding.evidence.length > 0 && (
                      <div className="mt-3">
                        <p className="text-gray-400 text-xs mb-2">Evidence:</p>
                        <ul className="list-disc list-inside text-gray-300 text-xs space-y-1">
                          {finding.evidence.map((evidence, evidenceIndex) => (
                            <li key={evidenceIndex}>{evidence}</li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>
                )) || (
                  <div className="text-center text-gray-400 py-8">
                    <p>No detective findings available.</p>
                  </div>
                )}
              </div>
            </div>
          </motion.div>
        </div>

        {/* Metadata */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.25 }}
          className="mt-8"
        >
          <div className="bg-gray-800/50 rounded-lg p-6 border border-gray-700">
            <h3 className="text-xl font-semibold text-white mb-4">
              📊 Investigation Metadata
            </h3>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-purple-400">
                  {data?.metadata?.investigation_id || 'N/A'}
                </div>
                <div className="text-sm text-gray-400">Investigation ID</div>
              </div>
              
              <div className="text-center">
                <div className="text-2xl font-bold text-blue-400">
                  {data?.metadata?.timestamp ? new Date(data.metadata.timestamp).toLocaleString() : 'N/A'}
                </div>
                <div className="text-sm text-gray-400">Timestamp</div>
              </div>
              
              <div className="text-center">
                <div className="text-2xl font-bold text-green-400">
                  {data?.metadata?.duration || 'N/A'}
                </div>
                <div className="text-sm text-gray-400">Duration</div>
              </div>
            </div>
          </div>
        </motion.div>

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
                // You might want to add a toast notification here
                alert('Results link copied to clipboard!');
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
