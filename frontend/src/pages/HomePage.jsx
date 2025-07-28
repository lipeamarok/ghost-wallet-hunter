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

const HomePage = () => {
  const [walletAddress, setWalletAddress] = useState('');
  const [isValidating, setIsValidating] = useState(false);
  const [activeTab, setActiveTab] = useState('investigation'); // investigation, squad, costs
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
    // Basic Solana wallet address validation
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

    // Simulate validation
    setTimeout(() => {
      setIsValidating(false);
      navigate(`/analysis?wallet=${walletAddress.trim()}`);
    }, 1000);
  };

  const features = [
    {
      icon: UserGroupIcon,
      title: 'Legendary Detective Squad',
      description: '7 AI-powered legendary detectives with real OpenAI & Grok integration for comprehensive analysis',
      stats: `${squadStatus?.total_detectives || 7} detectives`
    },
    {
      icon: CpuChipIcon,
      title: 'Real AI Analysis',
      description: 'Advanced AI powered by OpenAI GPT-3.5-turbo with Grok fallback for pattern detection',
      stats: `${userUsage?.requests_today || 0} requests today`
    },
    {
      icon: ChartBarIcon,
      title: 'Real-Time Monitoring',
      description: 'Live cost tracking and usage monitoring with comprehensive dashboard and budget controls',
      stats: `$${userUsage?.daily_cost?.toFixed(4) || '0.0000'} spent today`
    },
    {
      icon: ShieldCheckIcon,
      title: 'Risk Assessment',
      description: 'Advanced threat classification and compliance checking with real-time alerts and scoring',
      stats: `${squadStatus?.active_detectives || 0} active detectives`
    }
  ];

  return (
    <div className="relative">
      {/* Hero Section */}
      <section className="relative py-20 sm:py-32">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="text-center"
          >
            <h1 className="text-4xl sm:text-6xl font-bold text-white mb-6">
              <span className="block">Ghost</span>
              <span className="block bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
                Wallet Hunter
              </span>
            </h1>

            <p className="text-xl text-gray-300 mb-12 max-w-3xl mx-auto">
              Uncover hidden connections in the Solana blockchain with AI-powered analysis.
              Detect suspicious wallets, trace fund flows, and protect your assets.
            </p>

            {/* Wallet Input */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.2 }}
              className="max-w-2xl mx-auto"
            >
              <div className="flex flex-col sm:flex-row gap-4 p-6 bg-gray-800/50 backdrop-blur-sm rounded-2xl border border-gray-700">
                <input
                  type="text"
                  placeholder="Enter Solana wallet address..."
                  value={walletAddress}
                  onChange={(e) => setWalletAddress(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleAnalysis()}
                  className="flex-1 px-4 py-3 bg-gray-900/50 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                />
                <button
                  onClick={handleAnalysis}
                  disabled={isValidating}
                  className="px-8 py-3 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-medium rounded-lg hover:from-purple-700 hover:to-pink-700 focus:outline-none focus:ring-2 focus:ring-purple-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
                >
                  {isValidating ? (
                    <div className="flex items-center space-x-2">
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                      <span>Analyzing...</span>
                    </div>
                  ) : (
                    'Start Analysis'
                  )}
                </button>
              </div>
            </motion.div>

            {/* Example wallet */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.8, delay: 0.4 }}
              className="mt-6"
            >
              <button
                onClick={() => setWalletAddress('7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU')}
                className="text-sm text-gray-400 hover:text-gray-300 transition-colors"
              >
                Try example: 7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU
              </button>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 bg-gray-900/30 backdrop-blur-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
              Powerful Analytics at Your Fingertips
            </h2>
            <p className="text-lg text-gray-300 max-w-2xl mx-auto">
              Our AI-driven platform provides comprehensive insights into Solana wallet behavior and risk assessment.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="text-center p-6"
              >
                <div className="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl flex items-center justify-center">
                  <feature.icon className="w-8 h-8 text-white" />
                </div>
                <h3 className="text-xl font-semibold text-white mb-2">
                  {feature.title}
                </h3>
                <p className="text-gray-300">
                  {feature.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Dashboard Tabs Section */}
      <section className="py-20 bg-gray-900/50 backdrop-blur-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-12"
          >
            <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
              Real-Time Detective Intelligence
            </h2>
            <p className="text-lg text-gray-300 max-w-2xl mx-auto">
              Monitor your legendary detective squad and AI costs in real-time
            </p>
          </motion.div>

          {/* Tab Navigation */}
          <div className="flex justify-center mb-8">
            <div className="bg-gray-800/50 rounded-lg p-1">
              <button
                onClick={() => setActiveTab('investigation')}
                className={`px-6 py-2 rounded-md font-medium transition-all ${
                  activeTab === 'investigation'
                    ? 'bg-purple-600 text-white shadow-lg'
                    : 'text-gray-300 hover:text-white hover:bg-gray-700'
                }`}
              >
                <MagnifyingGlassIcon className="w-5 h-5 inline mr-2" />
                Investigation
              </button>
              <button
                onClick={() => setActiveTab('squad')}
                className={`px-6 py-2 rounded-md font-medium transition-all ${
                  activeTab === 'squad'
                    ? 'bg-purple-600 text-white shadow-lg'
                    : 'text-gray-300 hover:text-white hover:bg-gray-700'
                }`}
              >
                <UserGroupIcon className="w-5 h-5 inline mr-2" />
                Detective Squad
              </button>
              <button
                onClick={() => setActiveTab('costs')}
                className={`px-6 py-2 rounded-md font-medium transition-all ${
                  activeTab === 'costs'
                    ? 'bg-purple-600 text-white shadow-lg'
                    : 'text-gray-300 hover:text-white hover:bg-gray-700'
                }`}
              >
                <CurrencyDollarIcon className="w-5 h-5 inline mr-2" />
                AI Costs
              </button>
            </div>
          </div>

          {/* Tab Content */}
          <motion.div
            key={activeTab}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="min-h-[600px]"
          >
            {activeTab === 'investigation' && (
              <div className="bg-gray-800/30 rounded-xl p-8 border border-gray-700">
                <div className="text-center">
                  <MagnifyingGlassIcon className="w-16 h-16 mx-auto text-purple-400 mb-4" />
                  <h3 className="text-2xl font-bold text-white mb-4">
                    Start Your Investigation
                  </h3>
                  <p className="text-gray-300 mb-8 max-w-2xl mx-auto">
                    Enter a wallet address above to launch a full investigation with our legendary detective squad.
                    Each detective uses real AI analysis to provide comprehensive insights.
                  </p>
                  
                  {/* AI Test Button */}
                  <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
                    <button
                      onClick={() => testAI()}
                      disabled={isTestingAI}
                      className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
                    >
                      {isTestingAI ? (
                        <div className="flex items-center space-x-2">
                          <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                          <span>Testing AI...</span>
                        </div>
                      ) : (
                        '🤖 Test Real AI Integration'
                      )}
                    </button>
                    
                    {squadStatus && (
                      <div className="text-sm text-gray-400">
                        Squad Health: <span className="text-green-400 font-semibold">{squadStatus.squad_health}</span> | 
                        Active Detectives: <span className="text-blue-400 font-semibold">{squadStatus.active_detectives}/{squadStatus.total_detectives}</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'squad' && (
              <div className="bg-gray-800/30 rounded-xl p-6 border border-gray-700">
                {isLoadingSquad ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="w-8 h-8 border-2 border-purple-500 border-t-transparent rounded-full animate-spin mr-3"></div>
                    <span className="text-white">Loading detective squad...</span>
                  </div>
                ) : squadError ? (
                  <div className="text-center py-12">
                    <div className="text-red-400 mb-4">Failed to load detective squad</div>
                    <button
                      onClick={refreshSquadStatus}
                      className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg"
                    >
                      Retry
                    </button>
                  </div>
                ) : (
                  <DetectiveSquadDashboard />
                )}
              </div>
            )}

            {activeTab === 'costs' && (
              <div className="bg-gray-800/30 rounded-xl p-6 border border-gray-700">
                {isLoadingDashboard ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="w-8 h-8 border-2 border-green-500 border-t-transparent rounded-full animate-spin mr-3"></div>
                    <span className="text-white">Loading cost dashboard...</span>
                  </div>
                ) : (
                  <AICostDashboard />
                )}
              </div>
            )}
          </motion.div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8 }}
              viewport={{ once: true }}
            >
              <div className="text-4xl font-bold text-purple-400 mb-2">
                {squadStatus?.total_detectives || 7}
              </div>
              <div className="text-gray-300">AI Detectives Active</div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8, delay: 0.1 }}
              viewport={{ once: true }}
            >
              <div className="text-4xl font-bold text-purple-400 mb-2">
                ${dashboard?.total_cost?.toFixed(4) || '0.0000'}
              </div>
              <div className="text-gray-300">Total AI Costs</div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8, delay: 0.2 }}
              viewport={{ once: true }}
            >
              <div className="text-4xl font-bold text-purple-400 mb-2">
                {dashboard?.total_requests || 0}
              </div>
              <div className="text-gray-300">AI Requests Made</div>
            </motion.div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default HomePage;
