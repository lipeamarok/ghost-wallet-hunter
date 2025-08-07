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

const ResultsPage = () => {
  const { investigationId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const [activeSection, setActiveSection] = useState('summary');

  // Get results from navigation state or fetch them
  const navigationResults = location.state?.results;

  const { results, loading, error, refresh } = useInvestigationResults(investigationId, {
    autoRefresh: false,
    formatResults: true,
    initialData: navigationResults
  });

  useEffect(() => {
    if (!investigationId) {
      navigate('/');
    }
  }, [investigationId, navigate]);

  const handleExportResults = () => {
    if (results) {
      const dataStr = JSON.stringify(results, null, 2);
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

  if (loading) {
    return (
      <div className="min-h-screen relative">
        <ThreeBackground />
        <Header />
        <div className="relative z-10 min-h-screen flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-500 mx-auto mb-4"></div>
            <h2 className="text-xl font-semibold text-white">Loading Results...</h2>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen relative">
        <ThreeBackground />
        <Header />
        <div className="relative z-10 min-h-screen flex items-center justify-center">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-red-400 mb-4">Error Loading Results</h2>
            <p className="text-gray-400 mb-6">{error.message}</p>
            <div className="space-x-4">
              <button
                onClick={refresh}
                className="bg-blue-600 hover:bg-blue-700 px-6 py-2 rounded-md font-medium transition-colors"
              >
                Retry
              </button>
              <button
                onClick={() => navigate('/')}
                className="bg-gray-600 hover:bg-gray-700 px-6 py-2 rounded-md font-medium transition-colors"
              >
                Return to Home
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!results) {
    return (
      <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-400 mb-4">No Results Available</h2>
          <p className="text-gray-400 mb-6">Investigation results are not yet available.</p>
          <button
            onClick={() => navigate('/')}
            className="bg-blue-600 hover:bg-blue-700 px-6 py-2 rounded-md font-medium transition-colors"
          >
            Return to Home
          </button>
        </div>
      </div>
    );
  }

  const { summary, detailedFindings, metadata } = results;

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
                  {results.walletAddress} • {metadata.completionTime}
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
        {/* Risk Summary Card */}
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            {/* Risk Score */}
            <div className="text-center">
              <div className={`text-4xl font-bold mb-2 ${getRiskColor(summary.riskScore)}`}>
                {summary.riskScore}
              </div>
              <div className="text-sm text-gray-400">Risk Score</div>
              <div className={`text-xs px-2 py-1 rounded-full mt-2 ${getRiskBgColor(summary.riskScore)}`}>
                {summary.riskLevel}
              </div>
            </div>

            {/* Confidence */}
            <div className="text-center">
              <div className="text-4xl font-bold mb-2 text-blue-400">
                {summary.confidence}%
              </div>
              <div className="text-sm text-gray-400">Confidence</div>
              <div className="text-xs text-blue-300 mt-2">
                {summary.confidenceLevel}
              </div>
            </div>

            {/* Flagged Activities */}
            <div className="text-center">
              <div className="text-4xl font-bold mb-2 text-yellow-400">
                {summary.flaggedActivities?.length || 0}
              </div>
              <div className="text-sm text-gray-400">Flagged Activities</div>
              <div className="text-xs text-yellow-300 mt-2">
                Suspicious Patterns
              </div>
            </div>

            {/* Duration */}
            <div className="text-center">
              <div className="text-4xl font-bold mb-2 text-purple-400">
                {metadata.formattedDuration}
              </div>
              <div className="text-sm text-gray-400">Analysis Time</div>
              <div className="text-xs text-purple-300 mt-2">
                Multi-layer Scan
              </div>
            </div>
          </div>
        </div>

        {/* Section Navigation */}
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
                          The wallet shows a <span className={getRiskColor(summary.riskScore)}>
                          {summary.riskLevel.toLowerCase()}</span> risk level with a score of {summary.riskScore}/100.
                          Our analysis confidence is {summary.confidence}% based on {metadata.servicesUsed ?
                          Object.values(metadata.servicesUsed).filter(Boolean).length : 0} active services.
                        </p>
                      </div>

                      {summary.recommendations?.length > 0 && (
                        <div>
                          <h4 className="font-medium text-gray-300 mb-2">Recommendations</h4>
                          <ul className="space-y-2">
                            {summary.recommendations.slice(0, 3).map((rec, index) => (
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
                {summary.formattedFlags?.length > 0 ? (
                  <div className="space-y-4">
                    {summary.formattedFlags.map((flag, index) => (
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
                  {detailedFindings && Object.entries(detailedFindings).map(([source, findings]) => {
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
                  })}
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
                          <span className="font-mono">{results.investigationId}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Wallet Address:</span>
                          <span className="font-mono">{results.walletAddress}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Investigation Type:</span>
                          <span>{results.investigationType}</span>
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
