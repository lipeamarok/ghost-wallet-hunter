/**
 * Ghost Wallet Hunter - Detective Squad Component
 * ==============================================
 *
 * Exibe o status e resultados dos 7 agentes detective que analisaram a carteira.
 * Mostra conclusões, scores de risco, confiança e metodologia de cada agente.
 */

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  CheckCircleIcon,
  XCircleIcon,
  InformationCircleIcon,
  ChevronDownIcon,
  ChevronUpIcon
} from '@heroicons/react/24/outline';
import { DETECTIVE_INFO } from '../../types/investigation.types.js';

export default function DetectiveSquad({ detectives, summary }) {
  const [expandedAgent, setExpandedAgent] = useState(null);

  console.log('🕵️ DetectiveSquad:', {
    detectivesCount: detectives ? Object.keys(detectives).length : 0
  });

  if (!detectives) {
    return (
      <div className="bg-gray-800 rounded-lg p-6">
        <h2 className="text-xl font-bold text-white mb-4">🕵️ Detective Squad</h2>
        <p className="text-gray-400">No detective data available</p>
      </div>
    );
  }

  const agents = Object.entries(DETECTIVE_INFO);

  const getStatusIcon = (detective) => {
    if (!detective) return <XCircleIcon className="w-5 h-5 text-red-500" />;

    if (detective.isCompleted) {
      return <CheckCircleIcon className="w-5 h-5 text-green-500" />;
    } else {
      return <XCircleIcon className="w-5 h-5 text-red-500" />;
    }
  };

  const getStatusColor = (detective) => {
    if (!detective) return 'border-red-500 bg-red-50';
    return detective.isCompleted ? 'border-green-500 bg-green-50' : 'border-red-500 bg-red-50';
  };

  const getRiskColor = (riskScore) => {
    if (riskScore >= 70) return 'text-red-600';
    if (riskScore >= 40) return 'text-yellow-600';
    return 'text-green-600';
  };

  const toggleExpanded = (agentKey) => {
    setExpandedAgent(expandedAgent === agentKey ? null : agentKey);
  };

  return (
    <div className="bg-gray-800 rounded-lg p-6">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-bold text-white flex items-center">
          🕵️ Detective Squad Investigation
        </h2>

        <div className="text-sm text-gray-300">
          <span className="text-green-400">{summary?.successfulAgents || 0}</span>
          {' / '}
          <span className="text-gray-400">{summary?.totalAgents || 7}</span>
          {' '}agents completed
        </div>
      </div>

      {/* Squad Overview */}
      <div className="mb-6 p-4 bg-gray-700 rounded-lg">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
          <div>
            <div className="text-2xl font-bold text-white">{summary?.agentSuccessRate || '0'}%</div>
            <div className="text-xs text-gray-400">Success Rate</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-green-400">{summary?.successfulAgents || 0}</div>
            <div className="text-xs text-gray-400">Completed</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-red-400">{summary?.failedAgents || 0}</div>
            <div className="text-xs text-gray-400">Failed</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-blue-400">{summary?.totalAgents || 7}</div>
            <div className="text-xs text-gray-400">Total Agents</div>
          </div>
        </div>
      </div>

      {/* Individual Agents */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {agents.map(([agentKey, agentInfo]) => {
          const detective = detectives[agentKey];
          const isExpanded = expandedAgent === agentKey;

          console.log('🔍 DEBUG DetectiveSquad - Mapping agent:', { agentKey, agentInfo, detective });

          return (
            <motion.div
              key={agentKey}
              layout
              className={`border rounded-lg p-4 cursor-pointer transition-all ${
                detective?.isCompleted
                  ? 'border-green-500 bg-gray-700 hover:bg-gray-600'
                  : 'border-red-500 bg-gray-700 hover:bg-gray-600'
              }`}
              onClick={() => toggleExpanded(agentKey)}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center space-x-3">
                  <span className="text-2xl">{agentInfo.emoji}</span>
                  <div>
                    <h3 className="font-bold text-white text-sm">{agentInfo.name}</h3>
                    <p className="text-xs text-gray-400">{agentInfo.description}</p>
                  </div>
                </div>

                <div className="flex items-center space-x-2">
                  {getStatusIcon(detective)}
                  {isExpanded ? (
                    <ChevronUpIcon className="w-4 h-4 text-gray-400" />
                  ) : (
                    <ChevronDownIcon className="w-4 h-4 text-gray-400" />
                  )}
                </div>
              </div>

              {detective ? (
                <div className="space-y-2">
                  {/* Status básico sempre visível */}
                  <div className="flex justify-between items-center text-xs">
                    <span className={`px-2 py-1 rounded text-white ${
                      detective.isCompleted ? 'bg-green-600' : 'bg-red-600'
                    }`}>
                      {detective.isCompleted ? '✅ Completed' : '❌ Failed'}
                    </span>

                    {detective.isCompleted && (
                      <div className="flex space-x-2">
                        <span className={`font-medium ${getRiskColor(detective.riskScore)}`}>
                          Risk: {detective.riskScore}
                        </span>
                        <span className="text-blue-400">
                          Conf: {detective.confidence}%
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Detalhes expandidos */}
                  <AnimatePresence>
                    {isExpanded && (
                      <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: 'auto', opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        className="mt-3 pt-3 border-t border-gray-600"
                      >
                        {detective.isCompleted ? (
                          <div className="space-y-2">
                            <div className="text-xs text-gray-300">
                              <strong>Conclusion:</strong>
                              <p className="mt-1 text-gray-400 italic">
                                "{detective.conclusion}"
                              </p>
                            </div>

                            <div className="grid grid-cols-2 gap-2 text-xs">
                              <div>
                                <span className="text-gray-400">Methodology:</span>
                                <p className="text-white font-mono text-xs">
                                  {detective.methodology}
                                </p>
                              </div>
                              <div>
                                <span className="text-gray-400">Transactions:</span>
                                <p className="text-white">
                                  {detective.totalTransactions}
                                </p>
                              </div>
                            </div>

                            {detective.rpcMetrics && (
                              <div className="text-xs text-gray-400">
                                RPC: {detective.rpcMetrics.signatures_fetched || 0} signatures
                              </div>
                            )}
                          </div>
                        ) : (
                          <div className="text-xs text-red-400">
                            Investigation failed. Agent could not complete analysis.
                          </div>
                        )}
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              ) : (
                <div className="text-xs text-red-400">
                  Agent data not available
                </div>
              )}
            </motion.div>
          );
        })}
      </div>

      {/* Summary Footer */}
      {summary?.analysisAvailable && (
        <div className="mt-6 p-3 bg-blue-900/30 border border-blue-500 rounded-lg">
          <div className="flex items-center space-x-2">
            <InformationCircleIcon className="w-5 h-5 text-blue-400" />
            <span className="text-sm text-blue-300">
              Multi-agent analysis completed with {summary.agentSuccessRate}% success rate
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
