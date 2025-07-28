import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  MagnifyingGlassIcon,
  ShieldCheckIcon,
  CpuChipIcon,
  ChartBarIcon
} from '@heroicons/react/24/outline';
import toast from 'react-hot-toast';

const HomePage = () => {
  const [walletAddress, setWalletAddress] = useState('');
  const [isValidating, setIsValidating] = useState(false);
  const navigate = useNavigate();

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
      icon: CpuChipIcon,
      title: 'AI-Powered Analysis',
      description: 'Advanced machine learning algorithms powered by JuliaOS to detect suspicious patterns'
    },
    {
      icon: ChartBarIcon,
      title: 'Wallet Clustering',
      description: 'Intelligent grouping of related wallets based on transaction patterns and behaviors'
    },
    {
      icon: ShieldCheckIcon,
      title: 'Risk Assessment',
      description: 'Comprehensive risk scoring with detailed explanations and recommendations'
    },
    {
      icon: MagnifyingGlassIcon,
      title: 'Deep Analysis',
      description: 'Multi-layer investigation of wallet connections and transaction history'
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
              <div className="text-4xl font-bold text-purple-400 mb-2">1M+</div>
              <div className="text-gray-300">Wallets Analyzed</div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8, delay: 0.1 }}
              viewport={{ once: true }}
            >
              <div className="text-4xl font-bold text-purple-400 mb-2">99.9%</div>
              <div className="text-gray-300">Accuracy Rate</div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8, delay: 0.2 }}
              viewport={{ once: true }}
            >
              <div className="text-4xl font-bold text-purple-400 mb-2">&lt;5s</div>
              <div className="text-gray-300">Analysis Time</div>
            </motion.div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default HomePage;
