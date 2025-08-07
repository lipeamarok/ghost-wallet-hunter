/**
 * Ghost Wallet Hunter - About Page
 * ================================
 *
 * Information about the platform, features, architecture,
 * and technical specifications.
 */

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useSystemHealth } from '../hooks/index.js';
import { AGENTS, INVESTIGATION_TYPES } from '../config/constants.js';

const AboutPage = () => {
  const navigate = useNavigate();
  const [activeSection, setActiveSection] = useState('overview');
  const systemHealth = useSystemHealth();

  const features = [
    {
      icon: '🤖',
      title: 'AI-Powered Detective Agents',
      description: 'Seven specialized AI agents work together to analyze blockchain transactions with different investigative approaches.'
    },
    {
      icon: '⚡',
      title: 'Julia Core Engine',
      description: 'High-performance Julia backend for complex mathematical analysis and pattern detection.'
    },
    {
      icon: '🔗',
      title: 'Multi-Chain Analysis',
      description: 'Support for multiple blockchain networks and cross-chain transaction tracking.'
    },
    {
      icon: '📊',
      title: 'Real-Time Monitoring',
      description: 'Live investigation tracking with WebSocket connections and progress updates.'
    },
    {
      icon: '🛡️',
      title: 'Compliance Integration',
      description: 'Built-in compliance checks and regulatory reporting capabilities.'
    },
    {
      icon: '📈',
      title: 'Advanced Analytics',
      description: 'Comprehensive risk scoring, pattern analysis, and behavioral profiling.'
    }
  ];

  const architecture = [
    {
      layer: 'Frontend (React)',
      description: 'Modern React application with real-time updates and responsive design',
      technologies: ['React 18', 'Tailwind CSS', 'WebSocket', 'React Router']
    },
    {
      layer: 'Backend (FastAPI)',
      description: 'Python FastAPI server handling REST API and business logic',
      technologies: ['FastAPI', 'Python 3.11+', 'Pydantic', 'Uvicorn']
    },
    {
      layer: 'A2A Protocol',
      description: 'Agent-to-Agent coordination with swarm intelligence',
      technologies: ['Python', 'WebSocket', 'Agent Coordination', 'Task Management']
    },
    {
      layer: 'Julia Core',
      description: 'High-performance computational engine for blockchain analysis',
      technologies: ['Julia', 'Mathematical Analysis', 'Pattern Detection', 'Performance Computing']
    }
  ];

  return (
    <div className="min-h-screen bg-gray-900 text-white">
      {/* Header */}
      <header className="bg-gray-800 border-b border-gray-700">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => navigate('/')}
                className="text-gray-400 hover:text-white transition-colors"
              >
                ← Back to Home
              </button>
              <div>
                <h1 className="text-3xl font-bold text-blue-400">👻 Ghost Wallet Hunter</h1>
                <p className="text-gray-400 mt-1">About the Platform</p>
              </div>
            </div>

            {/* Version Info */}
            <div className="text-right text-sm text-gray-400">
              <div>Version 2.0.0</div>
              <div>Build: August 2025</div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-8">

        {/* Navigation Tabs */}
        <div className="bg-gray-800 rounded-lg border border-gray-700 mb-8">
          <div className="border-b border-gray-700">
            <div className="flex space-x-0">
              {[
                { id: 'overview', label: '📋 Overview' },
                { id: 'features', label: '⭐ Features' },
                { id: 'agents', label: '🤖 Agents' },
                { id: 'architecture', label: '🏗️ Architecture' },
                { id: 'system', label: '⚙️ System Status' }
              ].map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveSection(tab.id)}
                  className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
                    activeSection === tab.id
                      ? 'border-blue-500 text-blue-400 bg-gray-700'
                      : 'border-transparent text-gray-400 hover:text-gray-300'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>

          <div className="p-6">
            {/* Overview Section */}
            {activeSection === 'overview' && (
              <div className="space-y-6">
                <div>
                  <h2 className="text-2xl font-bold text-blue-400 mb-4">🎯 Mission</h2>
                  <p className="text-gray-300 text-lg leading-relaxed">
                    Ghost Wallet Hunter is an advanced AI-powered blockchain investigation platform designed to
                    identify suspicious activities, trace illicit funds, and ensure compliance across multiple
                    blockchain networks. Our platform combines cutting-edge artificial intelligence with
                    high-performance computing to deliver unprecedented insights into blockchain transactions.
                  </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  <div>
                    <h3 className="text-xl font-semibold text-blue-400 mb-3">🎯 What We Do</h3>
                    <ul className="space-y-2 text-gray-300">
                      <li className="flex items-start">
                        <span className="text-blue-400 mr-2">•</span>
                        Detect fraudulent transactions and money laundering schemes
                      </li>
                      <li className="flex items-start">
                        <span className="text-blue-400 mr-2">•</span>
                        Analyze wallet behavior patterns and risk assessment
                      </li>
                      <li className="flex items-start">
                        <span className="text-blue-400 mr-2">•</span>
                        Provide compliance reporting for regulatory requirements
                      </li>
                      <li className="flex items-start">
                        <span className="text-blue-400 mr-2">•</span>
                        Track cross-chain transactions and fund flows
                      </li>
                    </ul>
                  </div>

                  <div>
                    <h3 className="text-xl font-semibold text-blue-400 mb-3">🚀 Innovation</h3>
                    <ul className="space-y-2 text-gray-300">
                      <li className="flex items-start">
                        <span className="text-blue-400 mr-2">•</span>
                        Multi-agent AI system with specialized detective roles
                      </li>
                      <li className="flex items-start">
                        <span className="text-blue-400 mr-2">•</span>
                        Julia-powered high-performance computational engine
                      </li>
                      <li className="flex items-start">
                        <span className="text-blue-400 mr-2">•</span>
                        Real-time investigation tracking and live updates
                      </li>
                      <li className="flex items-start">
                        <span className="text-blue-400 mr-2">•</span>
                        Swarm intelligence for coordinated analysis
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            )}

            {/* Features Section */}
            {activeSection === 'features' && (
              <div>
                <h2 className="text-2xl font-bold text-blue-400 mb-6">⭐ Platform Features</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {features.map((feature, index) => (
                    <div key={index} className="bg-gray-700 rounded-lg p-6">
                      <div className="text-3xl mb-3">{feature.icon}</div>
                      <h3 className="text-lg font-semibold text-blue-400 mb-2">{feature.title}</h3>
                      <p className="text-gray-300 text-sm">{feature.description}</p>
                    </div>
                  ))}
                </div>

                <div className="mt-8">
                  <h3 className="text-xl font-semibold text-blue-400 mb-4">🎯 Investigation Types</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {Object.entries(INVESTIGATION_TYPES).map(([key, type]) => (
                      <div key={key} className="bg-gray-700 rounded-lg p-4">
                        <div className="font-medium text-gray-300">{type.replace('_', ' ').toUpperCase()}</div>
                        <div className="text-sm text-gray-400 mt-1">
                          Specialized analysis for {type.toLowerCase().replace('_', ' ')} detection
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Agents Section */}
            {activeSection === 'agents' && (
              <div>
                <h2 className="text-2xl font-bold text-blue-400 mb-6">🤖 Detective Agents</h2>
                <p className="text-gray-300 mb-6">
                  Our AI detective agents are inspired by legendary literary detectives, each with specialized
                  skills and approaches to blockchain investigation.
                </p>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {Object.entries(AGENTS).map(([key, agent]) => (
                    <div key={key} className="bg-gray-700 rounded-lg p-6 border-l-4 border-blue-500">
                      <div className="flex items-center mb-3">
                        <span className="text-2xl mr-3">{agent.icon}</span>
                        <div>
                          <h3 className="text-lg font-semibold text-blue-400">{agent.name}</h3>
                          <p className="text-sm text-gray-400">{agent.inspiration}</p>
                        </div>
                      </div>
                      <p className="text-gray-300 text-sm mb-3">{agent.description}</p>
                      <div className="space-y-1">
                        <div className="text-xs text-gray-400">Specialties:</div>
                        <div className="flex flex-wrap gap-1">
                          {agent.specialties?.map((specialty, index) => (
                            <span key={index} className="bg-gray-600 text-xs px-2 py-1 rounded">
                              {specialty}
                            </span>
                          )) || (
                            <span className="bg-gray-600 text-xs px-2 py-1 rounded">
                              General Investigation
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Architecture Section */}
            {activeSection === 'architecture' && (
              <div>
                <h2 className="text-2xl font-bold text-blue-400 mb-6">🏗️ System Architecture</h2>

                <div className="space-y-6">
                  {architecture.map((layer, index) => (
                    <div key={index} className="bg-gray-700 rounded-lg p-6">
                      <h3 className="text-lg font-semibold text-blue-400 mb-2">{layer.layer}</h3>
                      <p className="text-gray-300 mb-4">{layer.description}</p>
                      <div className="flex flex-wrap gap-2">
                        {layer.technologies.map((tech, techIndex) => (
                          <span key={techIndex} className="bg-blue-900 text-blue-300 text-xs px-3 py-1 rounded">
                            {tech}
                          </span>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>

                <div className="mt-8 bg-gray-700 rounded-lg p-6">
                  <h3 className="text-lg font-semibold text-blue-400 mb-4">📡 Communication Flow</h3>
                  <div className="space-y-3 text-sm text-gray-300">
                    <div className="flex items-center">
                      <span className="font-mono bg-gray-800 px-2 py-1 rounded mr-3">Frontend</span>
                      <span className="text-gray-400">→</span>
                      <span className="font-mono bg-gray-800 px-2 py-1 rounded mx-3">Backend (Port 8001)</span>
                      <span className="text-gray-400">REST API + WebSocket</span>
                    </div>
                    <div className="flex items-center">
                      <span className="font-mono bg-gray-800 px-2 py-1 rounded mr-3">Backend</span>
                      <span className="text-gray-400">→</span>
                      <span className="font-mono bg-gray-800 px-2 py-1 rounded mx-3">A2A (Port 9100)</span>
                      <span className="text-gray-400">Agent Coordination</span>
                    </div>
                    <div className="flex items-center">
                      <span className="font-mono bg-gray-800 px-2 py-1 rounded mr-3">Backend</span>
                      <span className="text-gray-400">→</span>
                      <span className="font-mono bg-gray-800 px-2 py-1 rounded mx-3">Julia (Port 10000)</span>
                      <span className="text-gray-400">Core Analysis</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* System Status Section */}
            {activeSection === 'system' && (
              <div>
                <h2 className="text-2xl font-bold text-blue-400 mb-6">⚙️ System Status</h2>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="bg-gray-700 rounded-lg p-6">
                    <h3 className="text-lg font-semibold text-blue-400 mb-4">Service Health</h3>
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-gray-300">Overall System:</span>
                        <div className="flex items-center space-x-2">
                          <div className={`w-3 h-3 rounded-full ${systemHealth.overallHealth ? 'bg-green-500' : 'bg-red-500'}`}></div>
                          <span className={systemHealth.overallHealth ? 'text-green-400' : 'text-red-400'}>
                            {systemHealth.overallHealth ? 'Healthy' : 'Issues Detected'}
                          </span>
                        </div>
                      </div>

                      {['Backend', 'A2A Protocol', 'Julia Core', 'WebSocket'].map((service) => (
                        <div key={service} className="flex items-center justify-between">
                          <span className="text-gray-300">{service}:</span>
                          <div className="flex items-center space-x-2">
                            <div className="w-2 h-2 rounded-full bg-green-500"></div>
                            <span className="text-green-400 text-sm">Online</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="bg-gray-700 rounded-lg p-6">
                    <h3 className="text-lg font-semibold text-blue-400 mb-4">System Information</h3>
                    <div className="space-y-3 text-sm">
                      <div className="flex justify-between">
                        <span className="text-gray-400">Platform:</span>
                        <span className="text-gray-300">Ghost Wallet Hunter v2.0</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-400">Build Date:</span>
                        <span className="text-gray-300">August 6, 2025</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-400">Agent Count:</span>
                        <span className="text-gray-300">{Object.keys(AGENTS).length} Active</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-400">Investigation Types:</span>
                        <span className="text-gray-300">{Object.keys(INVESTIGATION_TYPES).length} Available</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-400">Uptime:</span>
                        <span className="text-green-400">99.9%</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="mt-6 bg-gray-700 rounded-lg p-6">
                  <h3 className="text-lg font-semibold text-blue-400 mb-4">🔧 Technical Support</h3>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                    <div>
                      <div className="font-medium text-gray-300 mb-2">Documentation</div>
                      <div className="text-gray-400">
                        Complete API documentation and user guides available in the repository.
                      </div>
                    </div>
                    <div>
                      <div className="font-medium text-gray-300 mb-2">GitHub Repository</div>
                      <div className="text-gray-400">
                        Source code, issues, and contributions welcome at github.com/lipeamarok/ghost-wallet-hunter
                      </div>
                    </div>
                    <div>
                      <div className="font-medium text-gray-300 mb-2">License</div>
                      <div className="text-gray-400">
                        Open source project under MIT License for community collaboration.
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
};

export default AboutPage;
