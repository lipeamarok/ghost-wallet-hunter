/**
 * Ghost Wallet Hunter - Results Page
 * ==================================
 *
 * Investigation results display with risk analysis, flagged activities,
 * detailed findings, and export capabilities.
 */

import { useState, useEffect } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { useInvestigationResults } from '../hooks/index.js';
import Header from '../components/Layout/Header.jsx';
import ThreeBackground from '../components/Background/ThreeBackground.jsx';
import UnifiedResultsView from '../components/Results/UnifiedResultsView.jsx';

const ResultsPage = () => {
  const { investigationId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const [activeSection, setActiveSection] = useState('summary');

  // Get results from navigation state - THIS IS THE SOURCE OF TRUTH
  const navigationResults = location.state?.results;

  // Use navigationResults directly as the main data source, bypassing the hook.
  // The hook was adding a layer of complexity that caused data loss.
  const dataToDisplay = navigationResults;

  /*
  // This hook is disabled because it was losing the state from the previous navigation.
  // Using navigationResults directly is more reliable for the current synchronous flow.
  const { results, loading, error, refresh } = useInvestigationResults(investigationId, {
    autoRefresh: false,
    formatResults: true,
    initialData: navigationResults
  });
  */

  useEffect(() => {
    if (!investigationId) {
      navigate('/');
    }
    // If there's no data passed from the previous page, we can't show results.
    if (!dataToDisplay) {
      console.warn('No investigation data found in navigation state, redirecting to home.');
      navigate('/');
    }
  }, [investigationId, dataToDisplay, navigate]);

  const handleExportResults = () => {
    if (dataToDisplay) {
      const dataStr = JSON.stringify(dataToDisplay, null, 2);
      const dataBlob = new Blob([dataStr], { type: 'application/json' });

      const url = URL.createObjectURL(dataBlob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `investigation-${investigationId}-results.json`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    }
  };

  const getRiskColor = (riskScore) => {
    if (riskScore >= 80) return 'text-red-400';
    if (riskScore >= 50) return 'text-yellow-400';
    if (riskScore >= 20) return 'text-blue-400';
    return 'text-green-400';
  };

  const getRiskBgColor = (riskScore) => {
    if (riskScore >= 80) return 'bg-red-900';
    if (riskScore >= 50) return 'bg-yellow-900';
    if (riskScore >= 20) return 'bg-blue-900';
    return 'bg-green-900';
  };

  console.log('🎯 FINAL DATA CHECK:', {
    hasDataToDisplay: !!dataToDisplay,
    dataSource: navigationResults ? 'navigation' : 'none',
    dataKeys: dataToDisplay ? Object.keys(dataToDisplay) : 'none',
    hasDetectives: dataToDisplay?.detectives ? true : false,
    detectivesCount: dataToDisplay?.detectives?.length || 0,
    hasIndividualResults: dataToDisplay?.individual_results ? true : false,
    fullDataStructure: dataToDisplay
  });

  if (!dataToDisplay) {
    return (
      <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center">
        <div className="text-center max-w-md mx-auto">
          <h2 className="text-2xl font-bold text-gray-400 mb-4">No Results Available</h2>
          <p className="text-gray-400 mb-4">Investigation results are not available.</p>
          <div className="bg-blue-900/20 border border-blue-500/30 rounded-lg p-4 mb-6">
            <p className="text-blue-400 text-sm">
              <strong>Tip:</strong> In synchronous mode, results are available immediately after investigation completion.
              If you reached this page directly, please start a new investigation from the home page.
            </p>
          </div>
          <div className="space-x-4">
            <button
              onClick={() => navigate('/')}
              className="bg-blue-600 hover:bg-blue-700 px-6 py-2 rounded-md font-medium transition-colors"
            >
              Start New Investigation
            </button>
            <button
              onClick={() => navigate(-1)}
              className="bg-gray-600 hover:bg-gray-700 px-6 py-2 rounded-md font-medium transition-colors"
            >
              Go Back
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Extract all necessary data from dataToDisplay.results (not dataToDisplay directly)
  const resultsData = dataToDisplay?.results || dataToDisplay || {};
  const {
    summary = {},
    individual_results = {},
    detailedFindings = {},
    metadata = {},
    agents = [],
    timeline = [],
    network = {},
    detectives = undefined
  } = resultsData;

  // The primary source for detective data is the `detectives` property from the mapped response.
  // We fall back to `individual_results` for any legacy data structures.
  const detectivesData = resultsData?.detectives || resultsData?.individual_results || {};

  // Convert object of detectives into an array for processing
  const actualDetectives = Object.values(detectivesData);

  console.log('🔧 DEBUG - actualDetectives result:', {
    source: resultsData?.detectives ? 'detectives' : 'individual_results',
    count: actualDetectives.length,
    firstDetective: actualDetectives[0]
  });

  // Convert array to object for UnifiedResultsView compatibility
  const detectivesAsObject = actualDetectives.reduce((acc, detective, index) => {
    if (!detective) return acc;

    // Use detective.id if available, otherwise create a key
    const key = detective.id || `detective_${index}`;
    acc[key] = {
      ...detective,
      isCompleted: detective?.status === 'completed',
      detective: detective?.detective || detective?.agent_name || `Detective ${index + 1}`,
      agent_name: detective?.agent_name || detective?.detective,
      analysis: detective?.analysis || detective
    };
    return acc;
  }, {});

  console.log('🎯 FINAL detectivesAsObject before UnifiedResultsView:', {
    count: Object.keys(detectivesAsObject).length,
    keys: Object.keys(detectivesAsObject)
  });

  // EMERGENCY SUMMARY GENERATION if missing
  const emergencySummary = !summary || Object.keys(summary).length === 0 ? {
    riskScore: dataToDisplay?.consensus_risk_score || 0,
    confidence: dataToDisplay?.consensus_confidence || 0,
    riskLevel: 'LOW',
    confidenceLevel: 'HIGH'
  } : summary;

  // Fallback derivations with extra safety
  const riskScore = emergencySummary?.riskScore || dataToDisplay?.consensus_risk_score || 0;
  const confidence = emergencySummary?.confidence || dataToDisplay?.consensus_confidence || 0;
  const derivedRiskLevel = emergencySummary?.riskLevel || (riskScore >= 80 ? 'High' : riskScore >= 50 ? 'Medium' : riskScore >= 20 ? 'Low' : 'Very Low');
  const derivedConfidenceLevel = emergencySummary?.confidenceLevel || (confidence >= 90 ? 'Very High' : confidence >= 70 ? 'High' : confidence >= 50 ? 'Medium' : 'Low');

  return (
    <div className="min-h-screen relative text-white">
      <ThreeBackground />
      <Header />

      {/* Main Content */}
      <div className="relative z-10 min-h-screen pt-24">
        <div className="max-w-7xl mx-auto px-4 py-8">
          {/* Results Header */}
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
                  📊 Investigation Results
                </h1>
                <p className="text-gray-400 text-sm">
                  {dataToDisplay.walletAddress} • {metadata.completionTime}
                </p>
              </div>
            </div>

            <div className="flex items-center space-x-4">
              <button
                onClick={handleExportResults}
                className="bg-green-600 hover:bg-green-700 px-4 py-2 rounded-md text-sm font-medium transition-colors"
              >
                📥 Export Results
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 py-6">
        <UnifiedResultsView results={{
          ...resultsData,
          detectives: detectivesAsObject,
          summary: emergencySummary
        }} />

        {/* Section Navigation */}
        {/* Legacy raw view below hidden behind toggle (advanced) */}
        <div className="bg-gray-800 rounded-lg border border-gray-700 mb-6">
          <div className="border-b border-gray-700">
            <div className="flex space-x-0">
              {[
                { id: 'summary', label: '📋 Summary' },
                { id: 'flags', label: '🚨 Flagged Activities' },
                { id: 'detailed', label: '🔍 Detailed Findings' },
                { id: 'metadata', label: '📊 Metadata' }
              ].map((section) => (
                <button
                  key={section.id}
                  onClick={() => setActiveSection(section.id)}
                  className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
                    activeSection === section.id
                      ? 'border-blue-500 text-blue-400 bg-gray-700'
                      : 'border-transparent text-gray-400 hover:text-gray-300'
                  }`}
                >
                  {section.label}
                </button>
              ))}
            </div>
          </div>

          <div className="p-6">
            {/* Summary Section */}
            {activeSection === 'summary' && (
              <div className="space-y-6">
                <div>
                  <h3 className="text-lg font-semibold mb-4 text-blue-400">Investigation Summary</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-4">
                      <div>
                        <h4 className="font-medium text-gray-300 mb-2">Risk Assessment</h4>
                        <p className="text-sm text-gray-400">
                          The wallet shows a <span className={getRiskColor(summary?.riskScore || 0)}>
                          {derivedRiskLevel.toLowerCase()}</span> risk level with a score of {riskScore}/100.
                          Our analysis confidence is {summary?.confidence || 0}% based on {metadata?.servicesUsed ?
                          Object.values(metadata.servicesUsed).filter(Boolean).length : 0} active services.
                        </p>
                      </div>

                      {summary?.recommendations?.length > 0 && (
                        <div>
                          <h4 className="font-medium text-gray-300 mb-2">Recommendations</h4>
                          <ul className="space-y-2">
                            {summary?.recommendations?.slice(0, 3).map((rec, index) => (
                              <li key={index} className="text-sm text-gray-400 flex items-start">
                                <span className="text-blue-400 mr-2">•</span>
                                {rec.action || rec}
                              </li>
                            ))}
                          </ul>
                        </div>
                      )}
                    </div>

                    <div className="space-y-4">
                      {/* Service Usage */}
                      <div>
                        <h4 className="font-medium text-gray-300 mb-2">Services Used</h4>
                        <div className="space-y-2">
                          {metadata.servicesUsed && Object.entries(metadata.servicesUsed).map(([service, used]) => (
                            <div key={service} className="flex items-center justify-between text-sm">
                              <span className="text-gray-400 capitalize">{service}:</span>
                              <span className={used ? 'text-green-400' : 'text-gray-500'}>
                                {used ? '✓ Used' : '✗ Not Used'}
                              </span>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Flagged Activities Section */}
            {activeSection === 'flags' && (
              <div>
                <h3 className="text-lg font-semibold mb-4 text-blue-400">🚨 Flagged Activities</h3>
                {summary?.formattedFlags?.length > 0 ? (
                  <div className="space-y-4">
                    {summary.formattedFlags?.map((flag, index) => (
                      <div key={index} className="bg-gray-700 rounded-lg p-4 border-l-4 border-red-500">
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center space-x-2">
                            <span className="text-xl">{flag.icon}</span>
                            <span className="font-medium text-red-400">{flag.type.replace('_', ' ').toUpperCase()}</span>
                          </div>
                          <span className={`px-2 py-1 rounded text-xs ${
                            flag.severityLevel === 'Critical' ? 'bg-red-900 text-red-300' :
                            flag.severityLevel === 'High' ? 'bg-orange-900 text-orange-300' :
                            flag.severityLevel === 'Medium' ? 'bg-yellow-900 text-yellow-300' :
                            'bg-gray-600 text-gray-300'
                          }`}>
                            {flag.severityLevel}
                          </span>
                        </div>
                        <p className="text-sm text-gray-300">{flag.description}</p>
                        {flag.details && (
                          <p className="text-xs text-gray-400 mt-2">{flag.details}</p>
                        )}
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center text-gray-400 py-8">
                    <div className="text-4xl mb-4">✅</div>
                    <p>No suspicious activities detected</p>
                  </div>
                )}
              </div>
            )}

            {/* Detailed Findings Section */}
            {activeSection === 'detailed' && (
              <div>
                <h3 className="text-lg font-semibold mb-4 text-blue-400">🔍 Detailed Findings</h3>
                <div className="space-y-6">
                  {Array.isArray(actualDetectives) ? (
                    // If detectives is an array (new format)
                    actualDetectives.map((detective, index) => (
                      <div key={detective.agent_name || detective.detective || index} className="bg-gray-700 rounded-lg p-4">
                        <h4 className="font-medium text-gray-300 mb-3">
                          🕵️ {detective.detective || detective.agent_name || `Detective ${index + 1}`}
                        </h4>
                        <div className="bg-gray-800 rounded p-3 overflow-x-auto">
                          <pre className="text-xs text-gray-300 whitespace-pre-wrap">
                            {JSON.stringify(detective, null, 2)}
                          </pre>
                        </div>
                      </div>
                    ))
                  ) : actualDetectives && typeof actualDetectives === 'object' ? (
                    // If detectives is an object (legacy format)
                    Object.entries(actualDetectives).map(([source, findings]) => {
                      if (!findings || findings.error) return null;
                      return (
                        <div key={source} className="bg-gray-700 rounded-lg p-4">
                          <h4 className="font-medium text-gray-300 mb-3 capitalize">{source} Analysis</h4>
                          <div className="bg-gray-800 rounded p-3 overflow-x-auto">
                            <pre className="text-xs text-gray-300 whitespace-pre-wrap">
                              {JSON.stringify(findings, null, 2)}
                            </pre>
                          </div>
                        </div>
                      );
                    })
                  ) : (
                    <div className="text-gray-400 text-center py-8">
                      No detective findings available
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Metadata Section */}
            {activeSection === 'metadata' && (
              <div>
                <h3 className="text-lg font-semibold mb-4 text-blue-400">📊 Investigation Metadata</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <div>
                      <h4 className="font-medium text-gray-300 mb-2">Investigation Details</h4>
                      <div className="space-y-2 text-sm">
                        <div className="flex justify-between">
                          <span className="text-gray-400">Investigation ID:</span>
                          <span className="font-mono">{dataToDisplay.investigationId}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Wallet Address:</span>
                          <span className="font-mono">{dataToDisplay.walletAddress}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Investigation Type:</span>
                          <span>{dataToDisplay.investigationType}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Completion Time:</span>
                          <span>{metadata.completionTime}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Duration:</span>
                          <span>{metadata.formattedDuration}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <div>
                      <h4 className="font-medium text-gray-300 mb-2">Service Performance</h4>
                      <div className="space-y-2 text-sm">
                        {metadata.servicesUsed && Object.entries(metadata.servicesUsed).map(([service, used]) => (
                          <div key={service} className="flex justify-between">
                            <span className="text-gray-400 capitalize">{service}:</span>
                            <span className={used ? 'text-green-400' : 'text-red-400'}>
                              {used ? 'Successfully Used' : 'Not Available'}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ResultsPage;
