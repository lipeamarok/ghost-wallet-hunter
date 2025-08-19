/**
 * Ghost Wallet Hunter - Progress Dashboard Component
 * =================================================
 *
 * Displays overall investigation progress and agent statuses
 * for async investigations with real-time polling updates.
 */

import React from 'react';
import AgentStatusCard from './AgentStatusCard.jsx';

const ProgressDashboard = ({ investigation, isPolling }) => {
  const { currentInvestigation, overallProgress, serviceProgress } = investigation;

  if (!currentInvestigation) {
    return null;
  }

  const progress = currentInvestigation.progress || {};
  const agentsProgress = progress.agents || {};
  const consensusData = progress.consensus || {};

  // Extract agent statuses
  const agentEntries = Object.entries(agentsProgress).filter(([agentId]) =>
    agentId !== 'overall' && agentId !== 'consensus'
  );

  return (
    <div className="space-y-6">
      {/* Overall Progress */}
      <div className="bg-gray-900/80 backdrop-blur-sm rounded-lg border border-gray-700 p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold text-blue-400">🔍 Investigation Progress</h2>
          {isPolling && (
            <div className="flex items-center space-x-2 text-green-400">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
              <span className="text-sm">Live Updates</span>
            </div>
          )}
        </div>

        {/* Main Progress Bar */}
        <div className="mb-4">
          <div className="flex justify-between text-sm text-gray-400 mb-2">
            <span>Overall Progress</span>
            <span>{Math.round(progress.overall || 0)}%</span>
          </div>
          <div className="w-full bg-gray-700 rounded-full h-3">
            <div
              className="bg-gradient-to-r from-blue-500 to-blue-600 h-3 rounded-full transition-all duration-500"
              style={{ width: `${Math.max(0, Math.min(100, progress.overall || 0))}%` }}
            />
          </div>
        </div>

        {/* Status Information */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
          <div>
            <p className="text-gray-400 text-sm">Status</p>
            <p className="font-semibold text-white">{currentInvestigation.status || 'Unknown'}</p>
          </div>
          <div>
            <p className="text-gray-400 text-sm">Agents Active</p>
            <p className="font-semibold text-blue-400">{agentEntries.length}</p>
          </div>
          <div>
            <p className="text-gray-400 text-sm">Completed</p>
            <p className="font-semibold text-green-400">
              {agentEntries.filter(([_, agent]) => agent.status === 'completed').length}
            </p>
          </div>
          <div>
            <p className="text-gray-400 text-sm">Investigation ID</p>
            <p className="font-mono text-xs text-gray-300">
              {currentInvestigation.shortId || currentInvestigation.id?.slice(-8) || 'N/A'}
            </p>
          </div>
        </div>
      </div>

      {/* Consensus Preview */}
      {consensusData && Object.keys(consensusData).length > 0 && (
        <div className="bg-gray-900/80 backdrop-blur-sm rounded-lg border border-gray-700 p-6">
          <h3 className="text-lg font-bold text-yellow-400 mb-4">🎯 Consensus Analysis</h3>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-center">
            {consensusData.risk_score !== undefined && (
              <div>
                <p className="text-gray-400 text-sm">Risk Score</p>
                <p className={`text-2xl font-bold ${
                  consensusData.risk_score >= 70 ? 'text-red-400' :
                  consensusData.risk_score >= 40 ? 'text-yellow-400' : 'text-green-400'
                }`}>
                  {Math.round(consensusData.risk_score)}%
                </p>
              </div>
            )}
            {consensusData.confidence !== undefined && (
              <div>
                <p className="text-gray-400 text-sm">Confidence</p>
                <p className="text-2xl font-bold text-blue-400">
                  {Math.round(consensusData.confidence)}%
                </p>
              </div>
            )}
            {consensusData.agents_completed !== undefined && (
              <div>
                <p className="text-gray-400 text-sm">Agents Done</p>
                <p className="text-2xl font-bold text-purple-400">
                  {consensusData.agents_completed}/{consensusData.total_agents || agentEntries.length}
                </p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Agent Status Grid */}
      {agentEntries.length > 0 && (
        <div className="bg-gray-900/80 backdrop-blur-sm rounded-lg border border-gray-700 p-6">
          <h3 className="text-lg font-bold text-green-400 mb-4">👥 Detective Agents Status</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {agentEntries.map(([agentId, agentData]) => (
              <AgentStatusCard
                key={agentId}
                agentId={agentId}
                status={agentData.status || 'unknown'}
                progress={agentData.progress}
                riskScore={agentData.risk_score}
                confidence={agentData.confidence}
                lastUpdate={agentData.last_update || agentData.timestamp}
              />
            ))}
          </div>
        </div>
      )}

      {/* Debug Information (Development Only) */}
      {process.env.NODE_ENV === 'development' && currentInvestigation && (
        <div className="bg-gray-900/60 backdrop-blur-sm rounded-lg border border-gray-600 p-4">
          <h4 className="text-sm font-bold text-gray-400 mb-2">🐛 Debug Info</h4>
          <pre className="text-xs text-gray-500 overflow-auto">
            {JSON.stringify({
              status: currentInvestigation.status,
              progress: progress,
              pollingActive: isPolling,
              lastUpdate: currentInvestigation.lastUpdate
            }, null, 2)}
          </pre>
        </div>
      )}
    </div>
  );
};

export default ProgressDashboard;
