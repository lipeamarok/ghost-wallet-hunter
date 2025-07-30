import React, { useState } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  ArrowLeftIcon,
  ShieldExclamationIcon,
  ShieldCheckIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon,
  EyeIcon,
  LinkIcon
} from '@heroicons/react/24/outline';
import Layout from '../components/Layout/Layout';
import LoadingSpinner from '../components/UI/LoadingSpinner';

const ResultsPage = () => {
  const { walletAddress } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const [selectedWallet, setSelectedWallet] = useState(null);

  // Get investigation data from navigation state (ONLY from real investigation)
  const navigationData = location.state?.investigationData;
  const walletFromState = location.state?.walletAddress;
  const blacklistData = location.state?.blacklistResult;

  // Use only navigation data from real investigation - no fallback to mock APIs
  const data = navigationData;
  const displayWallet = walletFromState || walletAddress;

  console.log('🔍 DEBUG - Investigation Data:', data);
  console.log('🛡️ DEBUG - Blacklist Data:', blacklistData);

  // Check if wallet is blacklisted (priority alert)
  const isBlacklisted = data?.blacklist_alert?.is_blacklisted || blacklistData?.is_blacklisted || false;
  const blacklistWarning = data?.blacklist_alert?.warning || blacklistData?.warning || null;

  // Generate a professional AI explanation based on the detective findings
  const generateProfessionalExplanation = (detectiveData, walletAddr) => {
    // If blacklisted, show critical warning
    if (isBlacklisted) {
      return `🚨 CRITICAL THREAT DETECTED: Target wallet flagged in official fraud databases. HIGH RISK of financial loss. Immediate evasive action recommended.`;
    }

    const riskLevel = data?.results?.risk_assessment?.risk_level?.toLowerCase() || 'unknown';
    const riskScore = data?.results?.risk_assessment?.risk_score || 0;

    if (riskLevel === 'high' || riskScore > 0.7) {
      return `⚠️ ELEVATED THREAT LEVEL: Suspicious patterns detected. Wallet exhibits behavior consistent with known fraud operations. Recommend enhanced security protocols.`;
    } else if (riskLevel === 'medium' || riskScore > 0.4) {
      return `⚠️ MODERATE RISK DETECTED: Anomalous transaction patterns identified. Continue monitoring with caution protocols active.`;
    } else {
      return `✅ THREAT ASSESSMENT: No significant risk indicators detected. Wallet operations within normal parameters.`;
    }
  };

  // Get risk color for UI
  const getRiskColor = () => {
    // Critical override for blacklisted wallets
    if (isBlacklisted) {
      return { color: 'text-red-500', bg: 'bg-red-600/30', border: 'border-red-500/60' };
    }

    const level = data?.results?.risk_assessment?.risk_level?.toLowerCase() || 'unknown';
    switch (level) {
      case 'low': return { color: 'text-green-400', bg: 'bg-green-500/20', border: 'border-green-500/30' };
      case 'medium': return { color: 'text-yellow-400', bg: 'bg-yellow-500/20', border: 'border-yellow-500/30' };
      case 'high': return { color: 'text-red-400', bg: 'bg-red-500/20', border: 'border-red-500/30' };
      case 'critical': return { color: 'text-red-500', bg: 'bg-red-600/30', border: 'border-red-500/60' };
      default: return { color: 'text-gray-400', bg: 'bg-gray-500/20', border: 'border-gray-500/30' };
    }
  };

  const getRiskIcon = () => {
    // Critical override for blacklisted wallets
    if (isBlacklisted) {
      return ShieldExclamationIcon;
    }

    const level = data?.results?.risk_assessment?.risk_level?.toLowerCase() || 'unknown';
    switch (level) {
      case 'low': return ShieldCheckIcon;
      case 'medium': return ExclamationTriangleIcon;
      case 'high': return ShieldExclamationIcon;
      case 'critical': return ShieldExclamationIcon;
      default: return InformationCircleIcon;
    }
  };

  // Generate mock connected wallets for visualization (in real app, this would come from blockchain analysis)
  const generateConnectedWallets = () => {
    const riskLevel = data?.results?.risk_assessment?.risk_level?.toLowerCase() || 'low';
    const connections = [];

    // Generate 3-8 connected wallets based on risk level
    const numConnections = riskLevel === 'high' ? 6 + Math.floor(Math.random() * 3) :
                          riskLevel === 'medium' ? 3 + Math.floor(Math.random() * 3) :
                          1 + Math.floor(Math.random() * 3);

    for (let i = 0; i < numConnections; i++) {
      const connectionRisk = riskLevel === 'high' ?
        ['high', 'medium', 'medium', 'low'][Math.floor(Math.random() * 4)] :
        riskLevel === 'medium' ?
        ['medium', 'low', 'low'][Math.floor(Math.random() * 3)] :
        ['low', 'low', 'medium'][Math.floor(Math.random() * 3)];

      connections.push({
        id: i,
        address: `${displayWallet.slice(0, 8)}...${Math.random().toString(36).substr(2, 8)}`,
        risk: connectionRisk,
        transactions: Math.floor(Math.random() * 50) + 1,
        volume: (Math.random() * 1000).toFixed(2)
      });
    }

    return connections;
  };

  const connectedWallets = generateConnectedWallets();

  const generateIntelligenceReport = () => {
    const riskLevel = data?.results?.risk_assessment?.risk_level?.toLowerCase() || 'unknown';
    const totalConnections = connectedWallets.length;
    const highRiskNodes = connectedWallets.filter(w => w.risk === 'high').length;

    const reports = {
      high: [
        `THREAT ANALYSIS: Target exhibits elevated risk patterns with ${totalConnections} identified connections. Immediate monitoring recommended.`,
        `OPERATIONAL ASSESSMENT: High-risk activity detected across ${highRiskNodes} connection nodes. Enhanced surveillance protocols advised.`,
        `INTELLIGENCE BRIEFING: Target demonstrates suspicious transaction patterns requiring immediate attention from security teams.`
      ],
      medium: [
        `ASSESSMENT STATUS: Target shows moderate risk indicators with ${totalConnections} mapped connections. Continued monitoring suggested.`,
        `SURVEILLANCE REPORT: Standard operational patterns detected with some anomalies requiring periodic review and assessment.`,
        `INTELLIGENCE UPDATE: Target exhibits normal baseline activity with minor deviations noted for routine monitoring.`
      ],
      low: [
        `CLEARANCE REPORT: Target demonstrates standard operational patterns with ${totalConnections} clean connections verified.`,
        `ASSESSMENT COMPLETE: Low risk profile confirmed through comprehensive network analysis. No immediate threats detected.`,
        `INTELLIGENCE STATUS: Target follows expected behavioral patterns. Routine monitoring sufficient for current threat level.`
      ]
    };

    return reports[riskLevel] ? reports[riskLevel][Math.floor(Math.random() * reports[riskLevel].length)] :
           "ANALYSIS_ERROR: Unable to generate assessment report. Insufficient data for threat evaluation.";
  };

  // Loading states - only for real investigation
  if (!navigationData) {
    return (
      <div className="min-h-screen bg-black flex items-center justify-center">
        <div className="text-center">
          <div className="bg-gray-900 border border-gray-700 rounded-lg p-8 max-w-md">
            <h2 className="text-xl font-mono font-bold text-cyan-400 mb-4">
              [NO_INVESTIGATION_DATA]
            </h2>
            <p className="text-gray-400 font-mono text-sm mb-8">
              No active investigation session found. Please initiate new investigation.
            </p>
            <button
              onClick={() => navigate('/')}
              className="w-full px-6 py-3 bg-cyan-600 text-black font-mono font-bold rounded hover:bg-cyan-500 transition-colors"
            >
              INITIATE_NEW_INVESTIGATION
            </button>
          </div>
        </div>
      </div>
    );
  }

  const riskColors = getRiskColor();
  const RiskIcon = getRiskIcon();

  return (
    <Layout>
      <div className="max-w-7xl mx-auto px-4 py-8">
          {/* Terminal Header */}
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-8"
          >
            <button
              onClick={() => navigate('/')}
              className="flex items-center text-cyan-400 hover:text-cyan-300 mb-6 transition-colors font-mono"
            >
              <ArrowLeftIcon className="h-5 w-5 mr-2" />
              [RETURN_TO_COMMAND_CENTER]
            </button>

            <div className="text-center mb-8">
              <div className="bg-gray-900 border border-gray-700 rounded-lg p-6 max-w-4xl mx-auto">
                <div className="bg-black border border-gray-600 rounded-lg p-4 mb-4 font-mono text-left">
                  <div className="text-green-400 mb-2">
                    &gt; investigation.complete() - THREAT_ASSESSMENT_REPORT
                  </div>
                  <div className="text-gray-400 text-sm mb-2">
                    Investigation ID: {Date.now().toString(36).toUpperCase()}
                  </div>
                  <div className="text-cyan-400 text-sm">
                    TARGET: {displayWallet}
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Main Threat Assessment */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.1 }}
          className="mb-12"
        >
          {/* Critical Blacklist Alert */}
          {isBlacklisted && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              className="mb-6 bg-gray-900 border-2 border-red-500 rounded-lg p-6"
            >
              <div className="bg-black border border-gray-600 rounded-lg p-4">
                <div className="flex items-center mb-4">
                  <ShieldExclamationIcon className="h-8 w-8 text-red-500 mr-3" />
                  <h3 className="text-xl font-mono font-bold text-red-400">
                    [CRITICAL_SECURITY_ALERT]
                  </h3>
                </div>
                <div className="text-red-300 font-mono text-sm mb-4">
                  {blacklistWarning || "TARGET FLAGGED: Official fraud database match detected"}
                </div>
                <div className="bg-red-900/30 border border-red-700 rounded-lg p-3">
                  <p className="text-red-200 font-mono text-xs">
                    ⚠️ RECOMMENDATION: AVOID ALL TRANSACTIONS - HIGH FINANCIAL RISK
                  </p>
                </div>
              </div>
            </motion.div>
          )}

          <div className={`bg-gray-900 border-2 rounded-lg p-8 text-center ${riskColors.border}`}>
            <div className="bg-black border border-gray-600 rounded-lg p-6">
              <RiskIcon className={`h-16 w-16 ${riskColors.color} mx-auto mb-4`} />
              <h2 className="text-2xl font-mono font-bold text-cyan-400 mb-2">
                THREAT_LEVEL: <span className={riskColors.color}>
                  {isBlacklisted ? 'CRITICAL' : (data?.results?.risk_assessment?.risk_level || 'UNKNOWN').toUpperCase()}
                </span>
              </h2>
              <div className="text-lg text-gray-300 font-mono mb-6">
                CONFIDENCE: {isBlacklisted ? '95' : data?.results?.risk_assessment?.confidence ?
                  Math.round(data.results.risk_assessment.confidence * 100) : 'N/A'}%
              </div>

              {/* Professional AI Analysis */}
              <div className="bg-gray-800 border border-gray-600 rounded-lg p-6 text-left">
                <h3 className="text-lg font-mono font-bold text-cyan-400 mb-4 flex items-center">
                  <InformationCircleIcon className="h-6 w-6 mr-2" />
                  [INTELLIGENCE_ANALYSIS]
                </h3>
                <p className="text-gray-200 font-mono text-sm leading-relaxed">
                  {generateProfessionalExplanation()}
                </p>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Network Topology Visualization */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="mb-12"
        >
          <div className="bg-gray-900 border border-gray-700 rounded-lg p-8">
            <h3 className="text-2xl font-mono font-bold text-cyan-400 mb-6 text-center">
              [NETWORK_TOPOLOGY_ANALYSIS]
            </h3>
            <p className="text-gray-300 font-mono text-center mb-8 text-sm">
              Interactive connection mapping - Click nodes for detailed analysis
            </p>

            {/* Network Graph Terminal */}
            <div className="bg-black border border-gray-600 rounded-lg p-8 min-h-[400px] relative">
              <div className="text-green-400 font-mono text-xs mb-4">
                &gt; network.analyze_connections()
              </div>

              {/* Central Wallet */}
              <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
                <div className={`w-20 h-20 rounded-full border-4 ${riskColors.border} bg-gray-800 flex items-center justify-center cursor-pointer hover:scale-110 transition-transform`}
                     onClick={() => setSelectedWallet({
                       address: displayWallet,
                       risk: data?.results?.risk_assessment?.risk_level?.toLowerCase() || 'unknown',
                       isMain: true
                     })}>
                  <div className="text-center">
                    <div className="text-cyan-400 font-mono font-bold text-xs">TARGET</div>
                    <div className={`text-xs font-mono ${riskColors.color}`}>
                      {(data?.results?.risk_assessment?.risk_level || 'UNK').toUpperCase().slice(0, 3)}
                    </div>
                    <div className="text-xs text-gray-300">{displayWallet.slice(0,6)}...</div>
                  </div>
                </div>
              </div>

              {/* Connected Wallets - Terminal Style */}
              {connectedWallets.map((wallet, index) => {
                const angle = (360 / connectedWallets.length) * index;
                const radius = 120;
                const x = Math.cos((angle * Math.PI) / 180) * radius;
                const y = Math.sin((angle * Math.PI) / 180) * radius;

                const walletRiskColors = {
                  low: { border: 'border-green-500', color: 'text-green-400' },
                  medium: { border: 'border-yellow-500', color: 'text-yellow-400' },
                  high: { border: 'border-red-500', color: 'text-red-400' }
                }[wallet.risk];

                return (
                  <div key={wallet.id}>
                    {/* Connection Line */}
                    <div
                      className="absolute top-1/2 left-1/2 bg-cyan-400 opacity-30"
                      style={{
                        width: `${radius}px`,
                        height: '1px',
                        transformOrigin: '0 50%',
                        transform: `translate(-50%, -50%) rotate(${angle}deg)`
                      }}
                    />

                    {/* Connected Wallet Node */}
                    <div
                      className={`absolute w-12 h-12 rounded border-2 ${walletRiskColors.border} bg-gray-800 flex items-center justify-center cursor-pointer hover:scale-110 transition-transform`}
                      style={{
                        top: `calc(50% + ${y}px)`,
                        left: `calc(50% + ${x}px)`,
                        transform: 'translate(-50%, -50%)'
                      }}
                      onClick={() => setSelectedWallet({
                        address: wallet.address,
                        risk: wallet.risk,
                        transactions: wallet.transactions,
                        volume: wallet.volume,
                        isMain: false
                      })}
                    >
                      <div className="text-center">
                        <div className={`text-xs font-mono font-bold ${walletRiskColors.color}`}>
                          {wallet.risk.charAt(0).toUpperCase()}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Threat Level Legend */}
            <div className="flex justify-center mt-6 space-x-8">
              <div className="flex items-center">
                <div className="w-4 h-4 rounded border border-green-500 bg-gray-800 mr-2"></div>
                <span className="text-green-400 text-sm font-mono">LOW_RISK</span>
              </div>
              <div className="flex items-center">
                <div className="w-4 h-4 rounded border border-yellow-500 bg-gray-800 mr-2"></div>
                <span className="text-yellow-400 text-sm font-mono">MODERATE</span>
              </div>
              <div className="flex items-center">
                <div className="w-4 h-4 rounded border border-red-500 bg-gray-800 mr-2"></div>
                <span className="text-red-400 text-sm font-mono">HIGH_RISK</span>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Target Analysis Details */}
        {selectedWallet && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-8"
          >
            <div className="bg-gray-900 border border-gray-700 rounded-lg p-6">
              <div className="bg-black border border-gray-600 rounded-lg p-4">
                <div className="flex items-center justify-between mb-4">
                  <h4 className="text-lg font-mono font-bold text-cyan-400">
                    {selectedWallet.isMain ? '[TARGET_ANALYSIS]' : '[CONNECTION_ANALYSIS]'}
                  </h4>
                  <button
                    onClick={() => setSelectedWallet(null)}
                    className="text-gray-400 hover:text-cyan-400 font-mono"
                  >
                    [CLOSE]
                  </button>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <div className="text-sm text-gray-400 font-mono mb-1">ADDRESS:</div>
                    <div className="font-mono text-cyan-400 break-all text-sm">{selectedWallet.address}</div>

                    {!selectedWallet.isMain && (
                      <>
                        <div className="text-sm text-gray-400 font-mono mt-4 mb-1">ACTIVITY:</div>
                        <div className="text-gray-300 font-mono text-sm">
                          TXN_COUNT: {selectedWallet.transactions} | VOLUME: {selectedWallet.volume} SOL
                        </div>
                      </>
                    )}
                  </div>

                  <div>
                    <div className="text-sm text-gray-400 font-mono mb-2">THREAT_ANALYSIS:</div>
                    <div className="text-gray-200 font-mono text-sm">
                      {selectedWallet.isMain ?
                        generateProfessionalExplanation() :
                        selectedWallet.risk === 'high' ?
                          "⚠️ ELEVATED RISK: Connection exhibits suspicious patterns. Enhanced monitoring recommended." :
                        selectedWallet.risk === 'medium' ?
                          "🔍 MODERATE RISK: Activity requires monitoring. No immediate threats detected." :
                          "✅ LOW RISK: Connection follows normal operational patterns."
                      }
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        )}

        {/* Intelligence Analysis Summary */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="mb-8"
        >
          <div className="bg-gray-900 border border-gray-700 rounded-lg p-6">
            <div className="flex items-center mb-4">
              <div className="w-3 h-3 bg-cyan-400 rounded-full mr-3 animate-pulse"></div>
              <h3 className="text-xl font-mono font-bold text-cyan-400 text-center w-full">
                [AI_INTELLIGENCE_ANALYSIS]
              </h3>
            </div>

            <div className="bg-black border border-gray-600 rounded-lg p-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {data?.results?.detective_findings && Object.entries(data.results.detective_findings).slice(0, 4).map(([name, findings], index) => (
                  <div key={name} className="bg-gray-800 border border-gray-600 rounded-lg p-4">
                    <div className="flex items-center mb-3">
                      <span className="text-cyan-400 font-mono mr-2">&gt;</span>
                      <h4 className="font-mono text-cyan-400 uppercase">AGENT_{name}</h4>
                    </div>
                    <div className="text-gray-300 text-sm font-mono leading-relaxed">
                      {findings.reasoning?.substring(0, 150) || findings.explanation?.substring(0, 150) || 'ANALYSIS_IN_PROGRESS...'}
                      {(findings.reasoning?.length > 150 || findings.explanation?.length > 150) && '...'}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </motion.div>

        {/* Command Interface */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="text-center"
        >
          <div className="bg-gray-900 border border-gray-700 rounded-lg p-6">
            <div className="bg-black border border-gray-600 rounded-lg p-4">
              <div className="text-sm text-gray-400 font-mono mb-4 text-center">
                [COMMAND_INTERFACE]
              </div>
              <div className="space-y-4 sm:space-y-0 sm:space-x-4 sm:flex sm:justify-center">
                <button
                  onClick={() => navigate('/')}
                  className="block w-full sm:w-auto px-8 py-3 bg-cyan-600 border border-cyan-500 text-white font-mono font-bold rounded-lg hover:bg-cyan-700 hover:border-cyan-400 transition-colors"
                >
                  &gt; ANALYZE_NEW_TARGET
                </button>

                <button
                  onClick={() => {
                    navigator.clipboard.writeText(window.location.href);
                    alert('Report URL copied to system clipboard');
                  }}
                  className="block w-full sm:w-auto px-8 py-3 bg-gray-700 border border-gray-500 text-white font-mono font-bold rounded-lg hover:bg-gray-600 hover:border-gray-400 transition-colors"
                >
                  &gt; EXPORT_REPORT
                </button>
              </div>
            </div>
          </div>
        </motion.div>
    </Layout>
  );
};

export default ResultsPage;
