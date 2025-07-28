import React from 'react';
import { motion } from 'framer-motion';
import {
  CpuChipIcon,
  ShieldCheckIcon,
  BoltIcon,
  GlobeAltIcon
} from '@heroicons/react/24/outline';

const AboutPage = () => {
  const features = [
    {
      icon: CpuChipIcon,
      title: 'JuliaOS AI Integration',
      description: 'Powered by advanced JuliaOS AI agents for intelligent blockchain analysis and pattern recognition.'
    },
    {
      icon: ShieldCheckIcon,
      title: 'Advanced Security',
      description: 'Multi-layer security analysis including risk assessment, fraud detection, and compliance checking.'
    },
    {
      icon: BoltIcon,
      title: 'Real-time Analysis',
      description: 'Lightning-fast analysis with live blockchain data and instant results delivery.'
    },
    {
      icon: GlobeAltIcon,
      title: 'Solana Native',
      description: 'Built specifically for the Solana ecosystem with deep understanding of SOL transactions.'
    }
  ];

  const stats = [
    { label: 'Wallets Analyzed', value: '1M+' },
    { label: 'AI Accuracy', value: '99.9%' },
    { label: 'Average Response Time', value: '<5s' },
    { label: 'Security Score', value: 'A+' }
  ];

  return (
    <div className="min-h-screen py-12">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Hero Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-16"
        >
          <h1 className="text-4xl sm:text-5xl font-bold text-white mb-6">
            About <span className="bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
              Ghost Wallet Hunter
            </span>
          </h1>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto leading-relaxed">
            Advanced AI-powered blockchain analysis platform designed to uncover hidden connections
            and assess risks in the Solana ecosystem. Built with cutting-edge technology and
            powered by JuliaOS intelligent agents.
          </p>
        </motion.div>

        {/* Mission Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="mb-16"
        >
          <div className="bg-gray-800/50 rounded-2xl p-8 border border-gray-700">
            <h2 className="text-3xl font-bold text-white mb-6 text-center">Our Mission</h2>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
              <div>
                <p className="text-gray-300 text-lg leading-relaxed mb-6">
                  In the rapidly evolving world of cryptocurrency, transparency and security are paramount.
                  Ghost Wallet Hunter was created to bring advanced AI analysis to the Solana blockchain,
                  helping users, developers, and institutions understand wallet behaviors and assess risks.
                </p>
                <p className="text-gray-300 text-lg leading-relaxed">
                  Our platform combines the power of JuliaOS AI agents with deep blockchain expertise
                  to provide unparalleled insights into wallet clustering, transaction patterns, and risk assessment.
                </p>
              </div>
              <div className="text-center">
                <div className="w-48 h-48 mx-auto bg-gradient-to-br from-purple-500/20 to-pink-500/20 rounded-full flex items-center justify-center border border-purple-500/30">
                  <div className="text-6xl">🎯</div>
                </div>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Features Grid */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="mb-16"
        >
          <h2 className="text-3xl font-bold text-white text-center mb-12">Core Features</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {features.map((feature, index) => (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="bg-gray-800/50 rounded-xl p-6 border border-gray-700 hover:border-purple-500/50 transition-all duration-300"
              >
                <div className="flex items-start space-x-4">
                  <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-pink-500 rounded-lg flex items-center justify-center flex-shrink-0">
                    <feature.icon className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-white mb-2">{feature.title}</h3>
                    <p className="text-gray-300">{feature.description}</p>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* Stats Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="mb-16"
        >
          <h2 className="text-3xl font-bold text-white text-center mb-12">Platform Statistics</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {stats.map((stat, index) => (
              <motion.div
                key={stat.label}
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.8, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="text-center p-6 bg-gray-800/30 rounded-xl border border-gray-700"
              >
                <div className="text-3xl font-bold text-purple-400 mb-2">{stat.value}</div>
                <div className="text-gray-300 text-sm">{stat.label}</div>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* Technology Stack */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="mb-16"
        >
          <div className="bg-gray-800/50 rounded-2xl p-8 border border-gray-700">
            <h2 className="text-3xl font-bold text-white text-center mb-8">Technology Stack</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="text-center">
                <div className="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-blue-500 to-purple-500 rounded-xl flex items-center justify-center">
                  <span className="text-white font-bold text-xl">AI</span>
                </div>
                <h3 className="text-lg font-semibold text-white mb-2">JuliaOS AI</h3>
                <p className="text-gray-300 text-sm">Advanced AI agents for intelligent blockchain analysis</p>
              </div>

              <div className="text-center">
                <div className="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-green-500 to-blue-500 rounded-xl flex items-center justify-center">
                  <span className="text-white font-bold text-xl">⚡</span>
                </div>
                <h3 className="text-lg font-semibold text-white mb-2">Solana Blockchain</h3>
                <p className="text-gray-300 text-sm">Native integration with Solana RPC and WebSocket APIs</p>
              </div>

              <div className="text-center">
                <div className="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl flex items-center justify-center">
                  <span className="text-white font-bold text-xl">🚀</span>
                </div>
                <h3 className="text-lg font-semibold text-white mb-2">Modern Stack</h3>
                <p className="text-gray-300 text-sm">FastAPI backend with React frontend for optimal performance</p>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Contact Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="text-center"
        >
          <div className="bg-gradient-to-br from-purple-500/20 to-pink-500/20 rounded-2xl p-8 border border-purple-500/30">
            <h2 className="text-3xl font-bold text-white mb-4">Ready to Get Started?</h2>
            <p className="text-gray-300 text-lg mb-8 max-w-2xl mx-auto">
              Experience the power of AI-driven blockchain analysis. Analyze your first wallet now
              and discover hidden connections in the Solana ecosystem.
            </p>
            <button
              onClick={() => window.location.href = '/'}
              className="px-8 py-3 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-medium rounded-lg hover:from-purple-700 hover:to-pink-700 transition-all duration-200"
            >
              Start Analysis
            </button>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default AboutPage;
