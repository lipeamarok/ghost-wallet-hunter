import React from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  ArrowLeftIcon,
  ShieldExclamationIcon,
  ShieldCheckIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon
} from '@heroicons/react/24/outline';

import LoadingSpinner from '../components/UI/LoadingSpinner';

const ResultsPage = () => {
  const { walletAddress } = useParams();
  const navigate = useNavigate();
  const location = useLocation();

  // Get investigation data from navigation state (ONLY from real investigation)
  const navigationData = location.state?.investigationData;
  const walletFromState = location.state?.walletAddress;

  // Use only navigation data from real investigation - no fallback to mock APIs
  const data = navigationData;
  const displayWallet = walletFromState || walletAddress;

  // Debug: Log the REAL investigation data structure
  console.log('🔍 DEBUG - REAL Investigation Data:', {
    navigationData,
    finalData: data,
    walletFromState,
    walletAddress: displayWallet
  });

  const getRiskColor = (riskLevel) => {
    // Handle multiple data structures: demo, real investigation, and old format
    const level = riskLevel ||
                  data?.risk_assessment?.risk_level ||
                  data?.results?.legendary_consensus?.consensus_risk_level ||
                  data?.results?.risk_assessment?.risk_level ||
                  data?.risk_level;
    switch (level?.toLowerCase()) {
      case 'low': return 'text-green-400';
      case 'medium': return 'text-yellow-400';
      case 'high': return 'text-red-400';
      default: return 'text-gray-400';
    }
  };

  const getRiskIcon = (riskLevel) => {
    const level = riskLevel ||
                  data?.risk_assessment?.risk_level ||
                  data?.results?.legendary_consensus?.consensus_risk_level ||
                  data?.results?.risk_assessment?.risk_level ||
                  data?.risk_level;
    switch (level?.toLowerCase()) {
      case 'low': return ShieldCheckIcon;
      case 'medium': return ExclamationTriangleIcon;
      case 'high': return ShieldExclamationIcon;
      default: return InformationCircleIcon;
    }
  };

  const getRiskBg = (riskLevel) => {
    const level = riskLevel ||
                  data?.risk_assessment?.risk_level ||
                  data?.results?.legendary_consensus?.consensus_risk_level ||
                  data?.results?.risk_assessment?.risk_level ||
                  data?.risk_level;
    switch (level?.toLowerCase()) {
      case 'low': return 'bg-green-500/20 border-green-500/30';
      case 'medium': return 'bg-yellow-500/20 border-yellow-500/30';
      case 'high': return 'bg-red-500/20 border-red-500/30';
      default: return 'bg-gray-500/20 border-gray-500/30';
    }
  };

  // Loading states - only for real investigation
  if (!navigationData) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-white mb-4">No Investigation Data</h2>
          <p className="text-gray-400 mb-8">Please start a new investigation from the analysis page.</p>
          <button
            onClick={() => navigate('/')}
            className="px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
          >
            Start New Investigation
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
                    {data?.risk_assessment?.risk_level ||
                     data?.results?.legendary_consensus?.consensus_risk_level ||
                     data?.results?.risk_assessment?.risk_level ||
                     data?.risk_level || 'Unknown'}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-300">Confidence:</span>
                  <span className="text-white">
                    {data?.risk_assessment?.confidence ? Math.round(data.risk_assessment.confidence * 100) :
                     data?.results?.legendary_consensus?.consensus_confidence ? Math.round(data.results.legendary_consensus.consensus_confidence * 100) :
                     data?.confidence || 'N/A'}%
                  </span>
                </div>
                <div className="mt-4">
                  <p className="text-gray-300 text-sm mb-2">Summary:</p>
                  <p className="text-white">
                    {data?.risk_assessment?.summary ||
                     data?.risk_assessment?.reasoning ||
                     data?.results?.legendary_consensus?.consensus_reasoning ||
                     data?.risk_summary || 'No risk summary available.'}
                  </p>
                </div>
                {((data?.risk_assessment?.threats || data?.threats) ||
                  (data?.results?.legendary_consensus?.key_concerns)) && (
                  <div className="mt-4">
                    <p className="text-gray-300 text-sm mb-2">Key Concerns:</p>
                    <ul className="list-disc list-inside text-white space-y-1">
                      {(data?.risk_assessment?.threats ||
                        data?.threats ||
                        data?.results?.legendary_consensus?.key_concerns || []).map((threat, index) => (
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
                {/* Handle demo structure (detective_findings as objects) and old structure (findings as array) */}
                {data?.detective_findings ? (
                  // Demo format: detective_findings with named detectives
                  Object.entries(data.detective_findings).map(([detectiveName, detectiveData], index) => (
                    <div key={detectiveName} className="p-4 bg-gray-700/30 rounded-lg">
                      <div className="flex items-start justify-between mb-2">
                        <h4 className="font-medium text-purple-400 capitalize">
                          🕵️ {detectiveName} - {detectiveData.specialist || 'Detective Specialist'}
                        </h4>
                        <span className="text-xs text-gray-400">
                          {Math.round((detectiveData.confidence || 0) * 100)}% confidence
                        </span>
                      </div>

                      {/* Display findings/narrative */}
                      {detectiveData.narrative ? (
                        <div className="text-gray-300 text-sm mb-3 whitespace-pre-line">
                          {detectiveData.narrative}
                        </div>
                      ) : (
                        <>
                          {detectiveData.findings && detectiveData.findings.length > 0 && (
                            <div className="mb-3">
                              <p className="text-gray-400 text-xs mb-2">Key Findings:</p>
                              <ul className="list-disc list-inside text-gray-300 text-sm space-y-1">
                                {detectiveData.findings.map((finding, findingIndex) => (
                                  <li key={findingIndex}>{finding}</li>
                                ))}
                              </ul>
                            </div>
                          )}

                          {/* Display additional detective-specific data */}
                          {detectiveData.risk_indicators && detectiveData.risk_indicators.length > 0 && (
                            <div className="mt-3">
                              <p className="text-gray-400 text-xs mb-1">Risk Indicators:</p>
                              <div className="flex flex-wrap gap-1">
                                {detectiveData.risk_indicators.map((indicator, indicatorIndex) => (
                                  <span key={indicatorIndex} className="px-2 py-1 bg-red-500/20 text-red-300 text-xs rounded">
                                    {indicator.replace('_', ' ')}
                                  </span>
                                ))}
                              </div>
                            </div>
                          )}

                          {detectiveData.anomalies && detectiveData.anomalies.length > 0 && (
                            <div className="mt-3">
                              <p className="text-gray-400 text-xs mb-1">Anomalies:</p>
                              <div className="flex flex-wrap gap-1">
                                {detectiveData.anomalies.map((anomaly, anomalyIndex) => (
                                  <span key={anomalyIndex} className="px-2 py-1 bg-yellow-500/20 text-yellow-300 text-xs rounded">
                                    {anomaly.replace('_', ' ')}
                                  </span>
                                ))}
                              </div>
                            </div>
                          )}

                          {detectiveData.actions && detectiveData.actions.length > 0 && (
                            <div className="mt-3">
                              <p className="text-gray-400 text-xs mb-1">Recommended Actions:</p>
                              <div className="flex flex-wrap gap-1">
                                {detectiveData.actions.map((action, actionIndex) => (
                                  <span key={actionIndex} className="px-2 py-1 bg-blue-500/20 text-blue-300 text-xs rounded">
                                    {action.replace('_', ' ')}
                                  </span>
                                ))}
                              </div>
                            </div>
                          )}
                        </>
                      )}
                    </div>
                  ))
                ) : data?.results?.detective_findings ? (
                  // Real investigation format: results.detective_findings
                  Object.entries(data.results.detective_findings).map(([detectiveName, detectiveData], index) => (
                    <div key={detectiveName} className="p-4 bg-gray-700/30 rounded-lg">
                      <div className="flex items-start justify-between mb-2">
                        <h4 className="font-medium text-purple-400 capitalize">
                          🕵️ {detectiveName}
                        </h4>
                        <span className="text-xs text-gray-400">
                          {detectiveData.confidence ? `${Math.round(detectiveData.confidence * 100)}%` : 'N/A'} confidence
                        </span>
                      </div>
                      <p className="text-gray-300 text-sm mb-3">
                        {detectiveData.analysis || detectiveData.summary || JSON.stringify(detectiveData)}
                      </p>
                    </div>
                  ))
                ) : data?.findings ? (
                  // Old format: findings as array
                  data.findings.map((finding, index) => (
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
                  ))
                ) : (
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
                  {data?.investigation_id ||
                   data?.metadata?.investigation_id ||
                   data?.results?.case_metadata?.case_id || 'N/A'}
                </div>
                <div className="text-sm text-gray-400">Investigation ID</div>
              </div>

              <div className="text-center">
                <div className="text-2xl font-bold text-blue-400">
                  {data?.timestamp ? new Date(data.timestamp).toLocaleString() :
                   data?.metadata?.timestamp ? new Date(data.metadata.timestamp).toLocaleString() :
                   data?.results?.case_metadata?.timestamp ? new Date(data.results.case_metadata.timestamp).toLocaleString() : 'N/A'}
                </div>
                <div className="text-sm text-gray-400">Timestamp</div>
              </div>

              <div className="text-center">
                <div className="text-2xl font-bold text-green-400">
                  {data?.metadata?.investigation_duration ||
                   data?.metadata?.duration ||
                   data?.results?.case_metadata?.duration || 'N/A'}
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
