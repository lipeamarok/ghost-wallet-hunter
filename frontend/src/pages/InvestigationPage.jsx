/**
 * Ghost Wallet Hunter - Investigation Page (New)
 * ===============================================
 *
 * Detailed investigation monitoring page with real-time updates,
 * agent status, progress tracking, and live results.
 */

import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { useInvestigation } from '../hooks/index.js';
import Header from '../components/Layout/Header.jsx';
import ThreeBackground from '../components/Background/ThreeBackground.jsx';
import BlockchainTravel from '../components/Loading/BlockchainTravel.jsx';

const InvestigationPage = () => {
  const { investigationId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();

  const [isInvestigationActive, setIsInvestigationActive] = useState(true);

  // Get investigation data from navigation state
  const investigationData = location.state?.investigationData;
  const walletAddress = location.state?.walletAddress;
  const fallbackMode = location.state?.fallbackMode;

  const investigation = useInvestigation({
    autoConnect: true,
    onComplete: (results) => {
      console.log('Investigation completed:', results);
      setIsInvestigationActive(false);
      // Navigate to results page
      navigate(`/results/${investigationId || results.id}`, {
        state: {
          investigationId: investigationId || results.id,
          walletAddress: walletAddress,
          results: results
        }
      });
    }
  });

  // Load investigation on mount
  useEffect(() => {
    // Try to connect using ID from URL params first, then from state
    const idToConnect = investigationId || investigationData?.id;
    
    if (idToConnect && !investigation.hasActiveInvestigation) {
      // Try to connect to existing investigation
      investigation.connectToInvestigation(idToConnect);
    }
  }, [investigationId, investigationData, investigation]);

  const handleCancelInvestigation = async () => {
    if (window.confirm('Are you sure you want to cancel this investigation?')) {
      try {
        await investigation.cancelInvestigation();
        setIsInvestigationActive(false);
        navigate('/');
      } catch (error) {
        console.error('Failed to cancel investigation:', error);
        alert('Failed to cancel investigation: ' + error.message);
      }
    }
  };

  const handleViewResults = async () => {
    try {
      const results = await investigation.getResults();
      navigate('/results', {
        state: {
          investigationId: investigation.currentInvestigation?.id,
          walletAddress: walletAddress,
          results: results
        }
      });
    } catch (error) {
      console.error('Failed to get results:', error);
      alert('Failed to get results: ' + error.message);
    }
  };

  if (fallbackMode || (!investigationData && !investigation.hasActiveInvestigation)) {
    return (
      <div className="min-h-screen relative">
        <ThreeBackground />
        <Header />
        <div className="relative z-10 min-h-screen flex items-center justify-center">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-red-400 mb-4">Investigation Not Found</h2>
            <p className="text-gray-400 mb-6">The investigation you're looking for doesn't exist or has been completed.</p>
            <button
              onClick={() => navigate('/')}
              className="bg-blue-600 hover:bg-blue-700 px-6 py-2 rounded-md font-medium transition-colors"
            >
              Return to Home
            </button>
          </div>
        </div>
      </div>
    );
  }

  const currentInvestigation = investigation.currentInvestigation || investigationData;
  const isCompleted = investigation.isInvestigationCompleted;
  const isFailed = investigation.isInvestigationFailed;

  return (
    <div className="min-h-screen relative text-white">
      <ThreeBackground />
      <Header />

      {/* Show BlockchainTravel while investigation is active */}
      {isInvestigationActive && !isCompleted && !isFailed && <BlockchainTravel />}

      {/* Main Content */}
      <div className="relative z-10 min-h-screen pt-24">
        <div className="max-w-7xl mx-auto px-4 py-8">
          {/* Investigation Header */}
          <div className="bg-gray-900/80 backdrop-blur-sm rounded-lg border border-gray-700 p-6 mb-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <button
                  onClick={() => navigate('/')}
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  ← Back to Home
                </button>
                <div>
                  <h1 className="text-xl font-bold text-blue-400">
                    🔍 Investigation: {currentInvestigation?.id?.slice(0, 12) || 'Loading...'}
                  </h1>
                  <p className="text-gray-400 text-sm">
                    Target: {walletAddress || currentInvestigation?.walletAddress || 'Unknown'}
                  </p>
                </div>
              </div>

              <div className="flex items-center space-x-4">
                {/* Status Badge */}
                <div className={`px-3 py-1 rounded-full text-sm font-medium ${
                  isCompleted ? 'bg-green-900 text-green-300' :
                  isFailed ? 'bg-red-900 text-red-300' :
                  'bg-blue-900 text-blue-300'
                }`}>
                  {currentInvestigation?.status || 'Starting...'}
                </div>

                {/* Action Buttons */}
                {isInvestigationActive && !isCompleted && !isFailed && (
                  <button
                    onClick={handleCancelInvestigation}
                    className="bg-red-600 hover:bg-red-700 px-4 py-2 rounded-md text-sm font-medium transition-colors"
                  >
                    Cancel
                  </button>
                )}

                {(isCompleted || isFailed) && (
                  <button
                    onClick={handleViewResults}
                    className="bg-green-600 hover:bg-green-700 px-4 py-2 rounded-md text-sm font-medium transition-colors"
                  >
                    View Results
                  </button>
                )}
              </div>
            </div>
          </div>

          {/* Progress Overview */}
          <div className="bg-gray-900/80 backdrop-blur-sm rounded-lg border border-gray-700 p-6 mb-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-blue-400">📊 Investigation Progress</h2>
              <div className="text-sm text-gray-400">
                Started: {currentInvestigation?.startTime?.toLocaleString() || 'Just now'}
              </div>
            </div>

            {/* Progress Bar */}
            <div className="w-full bg-gray-700 rounded-full h-3 mb-4">
              <div
                className="bg-gradient-to-r from-blue-500 to-purple-600 h-3 rounded-full transition-all duration-500"
                style={{ width: `${currentInvestigation?.progress?.overall || 15}%` }}
              ></div>
            </div>

            {/* Service Status */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="text-center">
                <div className="text-sm text-gray-400">Backend</div>
                <div className="text-lg font-semibold text-green-400">
                  {currentInvestigation?.services?.backend || 'Active'}
                </div>
              </div>
              <div className="text-center">
                <div className="text-sm text-gray-400">A2A Swarm</div>
                <div className="text-lg font-semibold text-yellow-400">
                  {currentInvestigation?.services?.a2a || 'Coordinating'}
                </div>
              </div>
              <div className="text-center">
                <div className="text-sm text-gray-400">Julia Core</div>
                <div className="text-lg font-semibold text-purple-400">
                  {currentInvestigation?.services?.julia || 'Analyzing'}
                </div>
              </div>
            </div>
          </div>

          {/* Real-time Updates */}
          {investigation.recentUpdates && investigation.recentUpdates.length > 0 && (
            <div className="bg-gray-900/80 backdrop-blur-sm rounded-lg border border-gray-700 p-6">
              <h3 className="text-lg font-semibold text-blue-400 mb-4">🔄 Real-time Updates</h3>
              <div className="space-y-3 max-h-64 overflow-y-auto">
                {investigation.recentUpdates.map((update, index) => (
                  <div key={index} className="flex items-start space-x-3 p-3 bg-gray-800/50 rounded-lg">
                    <div className="text-xs text-gray-400 whitespace-nowrap">
                      {update.timestamp?.toLocaleTimeString()}
                    </div>
                    <div className="flex-1">
                      <div className="text-sm font-medium text-blue-300">
                        {update.source}
                      </div>
                      <div className="text-sm text-gray-300">
                        {update.message}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {investigation.recentUpdates.length > 0 && (
                <div className="mt-4">
                  <button
                    onClick={investigation.clearUpdates}
                    className="text-sm text-gray-400 hover:text-white transition-colors"
                  >
                    Clear Updates
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default InvestigationPage;
