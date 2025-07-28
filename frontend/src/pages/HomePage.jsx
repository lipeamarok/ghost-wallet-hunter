import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  MagnifyingGlassIcon,
  ShieldCheckIcon,
  CpuChipIcon,
  ChartBarIcon,
  UserGroupIcon,
  CurrencyDollarIcon
} from '@heroicons/react/24/outline';
import toast from 'react-hot-toast';
import { useDetectiveSquad, useAICostManagement } from '../hooks/useDetectiveAPI';
import DetectiveSquadDashboard from '../components/DetectiveSquad/DetectiveSquadDashboard';
import AICostDashboard from '../components/CostDashboard/AICostDashboard';
import Layout from '../components/Layout/Layout';

const HomePage = () => {
  const [walletAddress, setWalletAddress] = useState('');
  const [isValidating, setIsValidating] = useState(false);
  const [activeTab, setActiveTab] = useState('investigation');
  const navigate = useNavigate();

  // Use our custom hooks for real AI integration
  const {
    squadStatus,
    isLoadingSquad,
    squadError,
    testAI,
    isTestingAI,
    refreshSquadStatus
  } = useDetectiveSquad();

  const {
    dashboard,
    userUsage,
    isLoadingDashboard
  } = useAICostManagement();

  const validateWalletAddress = (address) => {
    const solanaRegex = /^[1-9A-HJ-NP-Za-km-z]{32,44}$/;
    return solanaRegex.test(address);
  };

  const handleAnalysis = async () => {
    if (!walletAddress.trim()) {
      toast.error('Please enter a wallet address');
      return;
    }

    if (!validateWalletAddress(walletAddress.trim())) {
      toast.error('Invalid Solana wallet address format');
      return;
    }

    setIsValidating(true);

    setTimeout(() => {
      setIsValidating(false);
      navigate(`/analysis?wallet=${walletAddress.trim()}`);
    }, 1000);
  };

  const features = [
    {
      icon: UserGroupIcon,
      title: 'LEGENDARY DETECTIVE SQUAD',
      description: 'Seven AI-powered specialized detectives with real OpenAI & Grok integration for comprehensive forensic analysis',
      stats: `${squadStatus?.total_detectives || 7} ACTIVE AGENTS`
    },
    {
      icon: CpuChipIcon,
      title: 'REAL AI INTELLIGENCE',
      description: 'Advanced neural analysis powered by OpenAI GPT-3.5-turbo with Grok fallback for pattern detection',
      stats: `${userUsage?.requests_today || 0} REQUESTS TODAY`
    },
    {
      icon: ChartBarIcon,
      title: 'REAL-TIME MONITORING',
      description: 'Live operational cost tracking and usage monitoring with comprehensive dashboard and budget controls',
      stats: `$${userUsage?.daily_cost?.toFixed(4) || '0.0000'} DAILY COST`
    },
    {
      icon: ShieldCheckIcon,
      title: 'THREAT ASSESSMENT',
      description: 'Advanced threat classification and compliance checking with real-time alerts and risk scoring',
      stats: `${squadStatus?.active_detectives || 0} OPERATIONAL`
    }
  ];

  return (
    <Layout>
      <div className="min-h-screen bg-black text-green-400">
        {/* Hero Command Interface */}
        <section className="py-16">
          <div className="max-w-7xl mx-auto px-4">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8 }}
              className="text-center mb-12"
            >
              <div className="bg-gray-900 border border-gray-700 rounded-lg p-8 max-w-4xl mx-auto">
                <h2 className="text-xl font-mono font-bold text-cyan-400 mb-6">
                  BLOCKCHAIN FORENSICS COMMAND CENTER
                </h2>

                <div className="bg-black border border-gray-600 rounded-lg p-6 mb-6 font-mono text-left">
                  <div className="text-green-400 mb-2">
                    &gt; ghost-wallet-hunter:~$ initialize_investigation
                  </div>
                  <div className="text-gray-400 text-sm mb-4">
                    Blockchain Intelligence Platform v2.0 - Ready for Operation
                  </div>
                  <div className="text-cyan-400">
                    Enter target wallet address for comprehensive analysis:
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="relative">
                    <input
                      type="text"
                      placeholder="Enter target Solana wallet address..."
                      value={walletAddress}
                      onChange={(e) => setWalletAddress(e.target.value)}
                      onKeyPress={(e) => e.key === 'Enter' && handleAnalysis()}
                      className="w-full px-4 py-3 bg-black border border-gray-600 rounded text-green-400 font-mono focus:outline-none focus:border-cyan-400 transition-colors"
                    />
                    <MagnifyingGlassIcon className="absolute right-3 top-3 h-6 w-6 text-gray-500" />
                  </div>

                  <button
                    onClick={handleAnalysis}
                    disabled={isValidating}
                    className="w-full py-3 bg-cyan-600 hover:bg-cyan-500 disabled:bg-gray-600 text-black font-mono font-bold rounded transition-colors"
                  >
                    {isValidating ? 'INITIALIZING INVESTIGATION...' : 'INITIATE INVESTIGATION'}
                  </button>

                  <button
                    onClick={() => setWalletAddress('7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU')}
                    className="text-sm text-gray-400 hover:text-cyan-400 transition-colors font-mono"
                  >
                    &gt; Load example target: 7xKXtg2C...osgAsU
                  </button>
                </div>
              </div>
            </motion.div>
          </div>
        </section>

      {/* Capabilities Section */}
      <section className="py-16 bg-gray-900/30">
        <div className="max-w-7xl mx-auto px-4">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-12"
          >
            <h2 className="text-2xl font-mono font-bold text-cyan-400 mb-4">
              OPERATIONAL CAPABILITIES
            </h2>
            <div className="text-gray-400 font-mono text-sm">
              Advanced AI-driven blockchain forensics and threat intelligence
            </div>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map((feature, index) => (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="bg-gray-900 border border-gray-700 rounded-lg p-6"
              >
                <div className="text-center">
                  <div className="w-12 h-12 mx-auto mb-4 bg-cyan-600 rounded flex items-center justify-center">
                    <feature.icon className="w-6 h-6 text-black" />
                  </div>
                  <h3 className="text-lg font-mono font-bold text-cyan-400 mb-2">
                    {feature.title}
                  </h3>
                  <p className="text-gray-300 text-sm mb-3 font-mono">
                    {feature.description}
                  </p>
                  <div className="text-xs text-green-400 font-mono font-bold">
                    {feature.stats}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Intelligence Dashboard */}
      <section className="py-16 bg-black">
        <div className="max-w-7xl mx-auto px-4">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-12"
          >
            <h2 className="text-2xl font-mono font-bold text-cyan-400 mb-4">
              INTELLIGENCE DASHBOARD
            </h2>
            <div className="text-gray-400 font-mono text-sm">
              Real-time operational status and resource monitoring
            </div>
          </motion.div>

          {/* Tab Navigation */}
          <div className="flex justify-center mb-8">
            <div className="bg-gray-900 border border-gray-700 rounded-lg p-1">
              <button
                onClick={() => setActiveTab('investigation')}
                className={`px-6 py-2 rounded-md font-mono font-medium transition-all ${
                  activeTab === 'investigation'
                    ? 'bg-cyan-600 text-black'
                    : 'text-gray-400 hover:text-cyan-400'
                }`}
              >
                [INVESTIGATION]
              </button>
              <button
                onClick={() => setActiveTab('squad')}
                className={`px-6 py-2 rounded-md font-mono font-medium transition-all ${
                  activeTab === 'squad'
                    ? 'bg-cyan-600 text-black'
                    : 'text-gray-400 hover:text-cyan-400'
                }`}
              >
                [AI_SQUAD]
              </button>
              <button
                onClick={() => setActiveTab('costs')}
                className={`px-6 py-2 rounded-md font-mono font-medium transition-all ${
                  activeTab === 'costs'
                    ? 'bg-cyan-600 text-black'
                    : 'text-gray-400 hover:text-cyan-400'
                }`}
              >
                [RESOURCE_COSTS]
              </button>
            </div>
          </div>

          {/* Tab Content */}
          <motion.div
            key={activeTab}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="bg-gray-900 border border-gray-700 rounded-lg p-8"
          >
            {activeTab === 'investigation' && (
              <div className="space-y-6">
                <div className="text-center">
                  <div className="text-cyan-400 font-mono text-lg font-bold mb-4">
                    [INVESTIGATION MODULE]
                  </div>
                  <div className="text-gray-300 font-mono text-sm mb-8 max-w-2xl mx-auto">
                    Deploy advanced AI investigative protocols to analyze target wallet patterns.
                    Real-time blockchain forensics with 7 specialized AI detectives.
                  </div>

                  {/* AI Test Terminal */}
                  <div className="bg-black border border-gray-600 rounded-lg p-4 max-w-md mx-auto">
                    <div className="text-green-400 font-mono text-xs mb-2">
                      &gt; system.test_ai_integration()
                    </div>
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => testAI()}
                        disabled={isTestingAI}
                        className="px-4 py-2 bg-cyan-600 hover:bg-cyan-500 disabled:bg-gray-600 text-black font-mono text-sm font-bold rounded transition-colors"
                      >
                        {isTestingAI ? 'TESTING...' : 'TEST_AI_SQUAD'}
                      </button>

                      {squadStatus && (
                        <div className="text-xs font-mono">
                          <span className="text-green-400">HEALTH:</span> {squadStatus.squad_health} |
                          <span className="text-cyan-400"> ACTIVE:</span> {squadStatus.active_detectives}/{squadStatus.total_detectives}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'squad' && (
              <div className="space-y-4">
                <div className="text-cyan-400 font-mono text-lg font-bold text-center mb-6">
                  [AI DETECTIVE SQUAD STATUS]
                </div>
                <div className="bg-black border border-gray-600 rounded-lg p-6">
                  {isLoadingSquad ? (
                    <div className="flex items-center justify-center py-8">
                      <div className="w-6 h-6 border-2 border-cyan-400 border-t-transparent rounded-full animate-spin mr-3"></div>
                      <span className="text-green-400 font-mono">Loading squad status...</span>
                    </div>
                  ) : squadError ? (
                    <div className="text-center py-8">
                      <div className="text-red-400 font-mono mb-4">ERROR: Squad connection failed</div>
                      <button
                        onClick={refreshSquadStatus}
                        className="px-4 py-2 bg-red-600 hover:bg-red-500 text-white font-mono rounded"
                      >
                        RETRY_CONNECTION
                      </button>
                    </div>
                  ) : (
                    <DetectiveSquadDashboard />
                  )}
                </div>
              </div>
            )}

            {activeTab === 'costs' && (
              <div className="space-y-4">
                <div className="text-cyan-400 font-mono text-lg font-bold text-center mb-6">
                  [RESOURCE COST MONITORING]
                </div>
                <div className="bg-black border border-gray-600 rounded-lg p-6">
                  {isLoadingDashboard ? (
                    <div className="flex items-center justify-center py-8">
                      <div className="w-6 h-6 border-2 border-green-400 border-t-transparent rounded-full animate-spin mr-3"></div>
                      <span className="text-green-400 font-mono">Loading cost analysis...</span>
                    </div>
                  ) : (
                    <AICostDashboard />
                  )}
                </div>
              </div>
            )}
          </motion.div>
        </div>
      </section>

      {/* System Metrics */}
      <section className="py-16 bg-gray-900/50">
        <div className="max-w-7xl mx-auto px-4">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-12"
          >
            <h2 className="text-2xl font-mono font-bold text-cyan-400 mb-4">
              SYSTEM METRICS
            </h2>
            <div className="text-gray-400 font-mono text-sm">
              Real-time operational statistics and performance data
            </div>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8 }}
              viewport={{ once: true }}
              className="bg-black border border-gray-700 rounded-lg p-6 text-center"
            >
              <div className="text-3xl font-mono font-bold text-cyan-400 mb-2">
                {squadStatus?.total_detectives || 7}
              </div>
              <div className="text-gray-300 font-mono text-sm">AI_DETECTIVES_ACTIVE</div>
              <div className="text-green-400 font-mono text-xs mt-1">
                STATUS: OPERATIONAL
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8, delay: 0.1 }}
              viewport={{ once: true }}
              className="bg-black border border-gray-700 rounded-lg p-6 text-center"
            >
              <div className="text-3xl font-mono font-bold text-cyan-400 mb-2">
                ${dashboard?.total_cost?.toFixed(4) || '0.0000'}
              </div>
              <div className="text-gray-300 font-mono text-sm">TOTAL_AI_COSTS</div>
              <div className="text-green-400 font-mono text-xs mt-1">
                BILLING: ACTIVE
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8, delay: 0.2 }}
              viewport={{ once: true }}
              className="bg-black border border-gray-700 rounded-lg p-6 text-center"
            >
              <div className="text-3xl font-mono font-bold text-cyan-400 mb-2">
                {dashboard?.total_requests || 0}
              </div>
              <div className="text-gray-300 font-mono text-sm">API_REQUESTS_MADE</div>
              <div className="text-green-400 font-mono text-xs mt-1">
                RATE_LIMIT: OK
              </div>
            </motion.div>
          </div>
          </div>
        </section>
      </div>
    </Layout>
  );
};export default HomePage;
