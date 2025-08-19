/**
 * Ghost Wallet Hunter - Agent Status Card Component
 * ================================================
 *
 * Displays real-time progress of individual detective agents
 * during async investigations.
 */

import React from 'react';

const AGENT_ICONS = {
  poirot: '🕵️',
  marple: '👵',
  spade: '🌶️',
  dupin: '🎭',
  marlowe: '🥃',
  raven: '🐦‍⬛',
  shadow: '👤'
};

const AGENT_NAMES = {
  poirot: 'Hercule Poirot',
  marple: 'Miss Marple',
  spade: 'Sam Spade',
  dupin: 'C. Auguste Dupin',
  marlowe: 'Philip Marlowe',
  raven: 'The Raven',
  shadow: 'Shadow Agent'
};

const getStatusColor = (status) => {
  switch (status) {
    case 'completed': return 'text-green-400 bg-green-900/20';
    case 'running': return 'text-blue-400 bg-blue-900/20';
    case 'failed': return 'text-red-400 bg-red-900/20';
    case 'pending': return 'text-yellow-400 bg-yellow-900/20';
    default: return 'text-gray-400 bg-gray-900/20';
  }
};

const getStatusIcon = (status) => {
  switch (status) {
    case 'completed': return '✅';
    case 'running': return '⚡';
    case 'failed': return '❌';
    case 'pending': return '⏳';
    default: return '❓';
  }
};

const AgentStatusCard = ({ agentId, status, progress, riskScore, confidence, lastUpdate }) => {
  const agentIcon = AGENT_ICONS[agentId] || '🔍';
  const agentName = AGENT_NAMES[agentId] || agentId.charAt(0).toUpperCase() + agentId.slice(1);
  const statusColor = getStatusColor(status);
  const statusIcon = getStatusIcon(status);

  return (
    <div className="bg-gray-800/60 backdrop-blur-sm rounded-lg border border-gray-700 p-4">
      {/* Agent Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center space-x-2">
          <span className="text-2xl">{agentIcon}</span>
          <div>
            <h3 className="font-semibold text-white">{agentName}</h3>
            <p className="text-xs text-gray-400">Agent ID: {agentId}</p>
          </div>
        </div>
        <div className={`px-2 py-1 rounded-full text-xs font-medium ${statusColor} flex items-center space-x-1`}>
          <span>{statusIcon}</span>
          <span>{status.charAt(0).toUpperCase() + status.slice(1)}</span>
        </div>
      </div>

      {/* Progress Bar */}
      {status === 'running' && progress !== undefined && (
        <div className="mb-3">
          <div className="flex justify-between text-xs text-gray-400 mb-1">
            <span>Progress</span>
            <span>{Math.round(progress)}%</span>
          </div>
          <div className="w-full bg-gray-700 rounded-full h-2">
            <div
              className="bg-blue-500 h-2 rounded-full transition-all duration-300"
              style={{ width: `${Math.max(0, Math.min(100, progress))}%` }}
            />
          </div>
        </div>
      )}

      {/* Results Preview */}
      {status === 'completed' && (riskScore !== undefined || confidence !== undefined) && (
        <div className="grid grid-cols-2 gap-3 mb-3">
          {riskScore !== undefined && (
            <div className="text-center">
              <p className="text-xs text-gray-400">Risk Score</p>
              <p className={`font-bold ${riskScore >= 70 ? 'text-red-400' : riskScore >= 40 ? 'text-yellow-400' : 'text-green-400'}`}>
                {Math.round(riskScore)}%
              </p>
            </div>
          )}
          {confidence !== undefined && (
            <div className="text-center">
              <p className="text-xs text-gray-400">Confidence</p>
              <p className="font-bold text-blue-400">{Math.round(confidence)}%</p>
            </div>
          )}
        </div>
      )}

      {/* Last Update */}
      {lastUpdate && (
        <div className="text-xs text-gray-500 text-center">
          Last update: {new Date(lastUpdate).toLocaleTimeString()}
        </div>
      )}
    </div>
  );
};

export default AgentStatusCard;
