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
import ProgressDashboard from '../components/Investigation/ProgressDashboard.jsx';
import { DISABLE_LEGACY_PROGRESS } from '../config/environment.js';

const InvestigationPage = () => {
  const { investigationId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();

  const [isInvestigationActive, setIsInvestigationActive] = useState(true);
  const [hasShownMinimumDuration, setHasShownMinimumDuration] = useState(false);

  // Get investigation data from navigation state
  const investigationData = location.state?.investigationData;
  const walletAddress = location.state?.walletAddress;
  const fallbackMode = location.state?.fallbackMode;
  const quickCompletion = location.state?.quickCompletion; // Flag for quick completion

  const investigation = useInvestigation({
    autoConnect: true,
    onComplete: (results) => {
      setIsInvestigationActive(false);
      // Auto-navigation disabled - use View Results button instead
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

  const handleViewResults = () => {
    const currentInvestigation = investigation.currentInvestigation;
    const results = currentInvestigation?.results;

    // EMERGENCY FIX: Use results from location state if hook state is missing
    const emergencyResults = location.state?.lastInvestigationResult;
    const finalResults = results || emergencyResults;

    console.log('🔍 DETAILED NAVIGATION DEBUG:', {
      hasCurrentInvestigation: !!currentInvestigation,
      currentInvestigationKeys: currentInvestigation ? Object.keys(currentInvestigation) : 'none',
      hasResults: !!results,
      hasEmergencyResults: !!emergencyResults,
      finalResultsSource: results ? 'hook' : emergencyResults ? 'location' : 'none',
      resultsKeys: finalResults ? Object.keys(finalResults) : 'none',
      resultsType: typeof finalResults,
      currentInvestigationStatus: currentInvestigation?.status,
      emergencyResultsKeys: emergencyResults ? Object.keys(emergencyResults) : 'none'
    });

    // Get the investigation ID from multiple sources
    const resultInvestigationId = investigationId ||
                                  investigation.currentInvestigation?.id ||
                                  finalResults?.investigation_id ||
                                  finalResults?.id ||
                                  emergencyResults?.investigationId;

    if (resultInvestigationId && finalResults) {
      // Navigate with results to avoid API call
      console.log('🚀 Navigating with results:', {
        investigationId: resultInvestigationId,
        hasResults: !!finalResults,
        resultKeys: Object.keys(finalResults || {}),
        resultsSource: results ? 'hook' : 'emergency',
        resultsPreview: {
          summary: !!finalResults.summary,
          detectives: !!finalResults.detectives,
          individual_results: !!finalResults.individual_results
        }
      });

      navigate(`/results/${resultInvestigationId}`, {
        state: {
          investigationId: resultInvestigationId,
          walletAddress: walletAddress,
          results: finalResults
        }
      });
    } else if (resultInvestigationId) {
      // Navigate without results (will trigger API call)
      console.log('⚠️ Navigating WITHOUT results - API call will be triggered');
      navigate(`/results/${resultInvestigationId}`, {
        state: {
          investigationId: resultInvestigationId,
          walletAddress: walletAddress
        }
      });
    } else {
      console.error('❌ No investigation ID available for manual navigation');
      // Fallback navigation
      navigate('/results', {
        state: {
          walletAddress: walletAddress,
          results: results
        }
      });
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
  const isCompleted = !!(currentInvestigation?.results?.consolidated || currentInvestigation?.results?.normalized || currentInvestigation?.progress?.overall === 100);
  const isFailed = investigation.isInvestigationFailed;

  // Removed auto-redirect - let the investigation hook handle the redirection timing

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

          {/* Progress Dashboard - Real-time Updates */}
          {!isCompleted && (
            <ProgressDashboard
              investigation={investigation}
              isPolling={investigation.isLoadingStatus || !investigation.webSocketConnected}
            />
          )}

          {/* Immediate Results Placeholder (in case redirect not yet processed) */}
          {isCompleted && currentInvestigation?.results && (
            <div className="bg-gray-900/80 backdrop-blur-sm rounded-lg border border-gray-700 p-6 mb-6">
              <h2 className="text-lg font-semibold text-green-400 mb-2">✅ Investigation Completed</h2>
              <p className="text-gray-300 text-sm mb-4">Redirecting to results...</p>
              <pre className="text-xs max-h-64 overflow-auto p-3 bg-black/40 rounded border border-gray-700 whitespace-pre-wrap">{JSON.stringify((currentInvestigation.results.consolidated || currentInvestigation.results)?.summary || currentInvestigation.results, null, 2)}</pre>
            </div>
          )}

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
