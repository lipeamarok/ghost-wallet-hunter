import React from 'react';
import { motion } from 'framer-motion';
import {
  CpuChipIcon,
  ShieldCheckIcon,
  BoltIcon,
  GlobeAltIcon,
  UserGroupIcon,
  ChartBarIcon
} from '@heroicons/react/24/outline';
import Layout from '../components/Layout/Layout';

const AboutPage = () => {
  const features = [
    {
      icon: UserGroupIcon,
      title: 'LEGENDARY DETECTIVE SQUAD',
      description: 'Seven specialized AI detectives with unique expertise: Hercule Poirot, Miss Marple, Sam Spade, Philip Marlowe, Auguste Dupin, The Shadow, and Raven.',
      stats: '7 ACTIVE AGENTS'
    },
    {
      icon: CpuChipIcon,
      title: 'REAL AI INTEGRATION',
      description: 'Advanced neural analysis powered by OpenAI GPT-3.5-turbo with Grok fallback for pattern detection and threat assessment.',
      stats: 'OPENAI + GROK'
    },
    {
      icon: ShieldCheckIcon,
      title: 'MULTI-SOURCE BLACKLIST',
      description: 'Real-time verification against Solana Foundation blacklist and Chainabuse database with automatic updates.',
      stats: '99.9% ACCURACY'
    },
    {
      icon: BoltIcon,
      title: 'REAL-TIME ANALYSIS',
      description: 'Lightning-fast blockchain forensics with live transaction monitoring and instant threat classification.',
      stats: '< 2S RESPONSE'
    },
    {
      icon: GlobeAltIcon,
      title: 'SOLANA NATIVE',
      description: 'Built specifically for Solana ecosystem with deep understanding of SOL transactions and DeFi protocols.',
      stats: 'MAINNET-BETA'
    },
    {
      icon: ChartBarIcon,
      title: 'COST MONITORING',
      description: 'Comprehensive AI usage tracking with real-time cost analysis, budget controls, and usage optimization.',
      stats: 'REAL-TIME TRACKING'
    }
  ];

  const stats = [
    { label: 'AI_DETECTIVES_ACTIVE', value: '7', status: 'OPERATIONAL' },
    { label: 'THREAT_DETECTION_RATE', value: '98.7%', status: 'OPTIMAL' },
    { label: 'AVG_RESPONSE_TIME', value: '<2s', status: 'FAST' },
    { label: 'SECURITY_RATING', value: 'A+', status: 'MAXIMUM' }
  ];

  const techStack = [
    {
      category: 'AI_INTELLIGENCE',
      icon: '🤖',
      title: 'OpenAI + Grok Integration',
      description: 'Multi-provider AI with automatic failover and cost optimization'
    },
    {
      category: 'BLOCKCHAIN_ANALYSIS',
      icon: '⚡',
      title: 'Solana Mainnet-Beta',
      description: 'Native RPC integration with WebSocket real-time monitoring'
    },
    {
      category: 'SECURITY_FRAMEWORK',
      icon: '🛡️',
      title: 'Multi-Source Verification',
      description: 'Solana Foundation + Chainabuse blacklist integration'
    }
  ];

  return (
    <Layout>
      <div className="max-w-7xl mx-auto px-4 py-16">
        {/* Hero Terminal Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-16"
        >
          <div className="bg-gray-900 border border-gray-700 rounded-lg p-8 max-w-4xl mx-auto">
            <div className="bg-black border border-gray-600 rounded-lg p-6 mb-6 font-mono text-left">
              <div className="text-green-400 mb-2">
                &gt; ghost-wallet-hunter:~$ system.about()
              </div>
              <div className="text-gray-400 text-sm mb-4">
                Initializing system overview and operational capabilities...
              </div>
              <div className="text-cyan-400 text-lg font-bold">
                GHOST WALLET HUNTER v2.0
              </div>
              <div className="text-gray-300 text-sm mt-2">
                Advanced AI-powered blockchain forensics platform designed to uncover hidden connections
                and assess threats in the Solana ecosystem. Powered by 7 legendary AI detectives
                with real OpenAI and Grok integration.
              </div>
            </div>
          </div>
        </motion.div>

        {/* Mission Command Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="mb-16"
        >
          <div className="bg-gray-900 border border-gray-700 rounded-lg p-8">
            <h2 className="text-2xl font-mono font-bold text-cyan-400 text-center mb-8">
              [MISSION PROTOCOL]
            </h2>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
              <div className="space-y-6">
                <div className="bg-black border border-gray-600 rounded-lg p-4">
                  <div className="text-green-400 font-mono text-sm mb-2">
                    &gt; mission.objectives.primary()
                  </div>
                  <p className="text-gray-300 font-mono text-sm leading-relaxed">
                    In the rapidly evolving cryptocurrency landscape, transparency and security are critical.
                    Ghost Wallet Hunter brings advanced AI forensics to Solana blockchain, enabling users,
                    developers, and institutions to understand wallet behaviors and assess threat levels.
                  </p>
                </div>
                <div className="bg-black border border-gray-600 rounded-lg p-4">
                  <div className="text-green-400 font-mono text-sm mb-2">
                    &gt; mission.capabilities.core()
                  </div>
                  <p className="text-gray-300 font-mono text-sm leading-relaxed">
                    Our platform combines 7 specialized AI detectives with multi-source blacklist verification
                    to provide unparalleled insights into wallet clustering, transaction patterns, and risk assessment.
                  </p>
                </div>
              </div>
              <div className="text-center">
                <div className="bg-black border border-gray-600 rounded-lg p-6">
                  <div className="text-cyan-400 font-mono text-xs mb-4">
                    [SYSTEM STATUS]
                  </div>
                  <div className="text-6xl mb-4">🎯</div>
                  <div className="space-y-2 text-xs font-mono">
                    <div className="text-gray-400">
                      <span className="text-cyan-400">STATUS:</span> OPERATIONAL
                    </div>
                    <div className="text-gray-400">
                      <span className="text-cyan-400">MISSION:</span> ACTIVE
                    </div>
                    <div className="text-gray-400">
                      <span className="text-cyan-400">THREAT_LEVEL:</span> MONITORED
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Operational Capabilities */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="mb-16"
        >
          <h2 className="text-2xl font-mono font-bold text-cyan-400 text-center mb-12">
            [OPERATIONAL CAPABILITIES]
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
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
                  <p className="text-gray-300 text-sm mb-3 font-mono leading-relaxed">
                    {feature.description}
                  </p>
                  <div className="text-xs text-green-400 font-mono font-bold">
                    {feature.stats}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* System Metrics */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="mb-16"
        >
          <h2 className="text-2xl font-mono font-bold text-cyan-400 text-center mb-12">
            [SYSTEM METRICS]
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {stats.map((stat, index) => (
              <motion.div
                key={stat.label}
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.8, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="bg-black border border-gray-700 rounded-lg p-6 text-center"
              >
                <div className="text-3xl font-mono font-bold text-cyan-400 mb-2">
                  {stat.value}
                </div>
                <div className="text-gray-300 font-mono text-xs mb-1">
                  {stat.label}
                </div>
                <div className="text-green-400 font-mono text-xs">
                  {stat.status}
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* Technology Framework */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="mb-16"
        >
          <div className="bg-gray-900 border border-gray-700 rounded-lg p-8">
            <h2 className="text-2xl font-mono font-bold text-cyan-400 text-center mb-8">
              [TECHNOLOGY FRAMEWORK]
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {techStack.map((tech, index) => (
                <motion.div
                  key={tech.category}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.8, delay: index * 0.1 }}
                  viewport={{ once: true }}
                  className="text-center"
                >
                  <div className="bg-black border border-gray-600 rounded-lg p-6">
                    <div className="text-cyan-400 font-mono text-xs mb-2">
                      [{tech.category}]
                    </div>
                    <div className="text-4xl mb-4">{tech.icon}</div>
                    <h3 className="text-lg font-mono font-bold text-cyan-400 mb-2">
                      {tech.title}
                    </h3>
                    <p className="text-gray-300 font-mono text-sm">
                      {tech.description}
                    </p>
                  </div>
                </motion.div>
              ))}
            </div>
          </div>
        </motion.div>

        {/* Command Interface */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="text-center"
        >
          <div className="bg-gray-900 border border-gray-700 rounded-lg p-8">
            <div className="bg-black border border-gray-600 rounded-lg p-6 mb-6">
              <div className="text-green-400 font-mono text-sm mb-2">
                &gt; system.initialize_investigation()
              </div>
              <h2 className="text-2xl font-mono font-bold text-cyan-400 mb-4">
                READY FOR DEPLOYMENT
              </h2>
              <p className="text-gray-300 font-mono text-sm mb-6 max-w-2xl mx-auto">
                Experience advanced AI-driven blockchain forensics. Deploy your first investigation
                and discover hidden threat patterns in the Solana ecosystem.
              </p>
              <div className="text-gray-400 font-mono text-xs mb-4">
                [COMMAND_READY] All systems operational - awaiting user input
              </div>
            </div>
            <button
              onClick={() => window.location.href = '/'}
              className="px-8 py-3 bg-cyan-600 hover:bg-cyan-500 text-black font-mono font-bold rounded transition-colors"
            >
              INITIATE_INVESTIGATION
            </button>
          </div>
        </motion.div>
      </div>
    </Layout>
  );
};

export default AboutPage;
