import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate, useSearchParams } from 'react-router-dom';
import { motion } from 'framer-motion';
import { legendarySquadService } from '../services/detectiveAPI';

export default function ResultsPageSimple() {
  const location = useLocation();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [loading, setLoading] = useState(true);
  const [results, setResults] = useState(null);
  const [error, setError] = useState(null);
  const [walletAddress, setWalletAddress] = useState('');

  // Function to generate simple explanation from detective findings
  const generateSimpleExplanation = (detectives, riskLevel, riskScore, consensusData) => {
    if (!detectives || Object.keys(detectives).length === 0) {
      return 'The Legendary Squad has completed their analysis, but detailed explanations are not available at this time.';
    }

    const confidencePercent = Math.round(riskScore * 100);
    const consensus = consensusData.detective_consensus || 'Squad analysis complete';
    const threatClassification = consensusData.threat_classification || '';

    // Check for critical threats
    const isCritical = threatClassification.includes('CRITICAL') ||
                      threatClassification.includes('BLACKLISTED') ||
                      threatClassification.includes('MONEY LAUNDERING') ||
                      threatClassification.includes('CRIMINAL NETWORK');

    let baseExplanation;

    if (isCritical) {
      baseExplanation = `🚨 CRITICAL THREAT DETECTED: The Legendary Detective Squad has identified this wallet as posing an EXTREME SECURITY RISK with ${confidencePercent}% confidence. ${consensus}. This address shows clear evidence of involvement in illegal activities and should be avoided at all costs.`;
    } else {
      baseExplanation = `The Legendary Detective Squad has analyzed this wallet and determined a ${typeof riskLevel === 'string' ? riskLevel.toLowerCase() : String(riskLevel || 'unknown').toLowerCase()} risk level with ${confidencePercent}% confidence. ${consensus}.`;
    }

    // Add specific findings from different detectives using real data
    const findings = [];

    // Poirot - Transaction analysis
    if (detectives.poirot_transaction_analysis?.explanation) {
      const poirotRisk = Math.round(detectives.poirot_transaction_analysis.risk_score * 100);
      const riskLevel = detectives.poirot_transaction_analysis.risk_level;
      if (poirotRisk >= 70) {
        findings.push(`🕵️ Hercule Poirot detected DANGEROUS ${typeof riskLevel === 'string' ? riskLevel.toLowerCase() : String(riskLevel || 'unknown').toLowerCase()} risk patterns (${poirotRisk}% confidence) with clear signs of criminal activity.`);
      } else {
        findings.push(`Hercule Poirot detected ${typeof riskLevel === 'string' ? riskLevel.toLowerCase() : String(riskLevel || 'unknown').toLowerCase()} risk patterns (${poirotRisk}% confidence).`);
      }
    }

    // Marple - Pattern detection
    if (detectives.marple_pattern_detection?.summary_of_observations?.risk_evaluation?.overall_concern) {
      const marpleConcern = detectives.marple_pattern_detection.summary_of_observations.risk_evaluation.overall_concern;
      if (marpleConcern === 'High') {
        findings.push(`👵 Miss Marple identified HIGHLY CONCERNING behavioral patterns indicating deceptive and potentially criminal practices.`);
      } else {
        findings.push(`Miss Marple identified ${typeof marpleConcern === 'string' ? marpleConcern.toLowerCase() : String(marpleConcern || 'unknown').toLowerCase()} concern behavioral patterns.`);
      }
    }

    // Spade - Risk assessment
    if (detectives.spade_risk_assessment?.risk_score > 0.7) {
      const spadeRisk = Math.round(detectives.spade_risk_assessment.risk_score * 100);
      findings.push(`🚬 Sam Spade flagged MULTIPLE HIGH-RISK INDICATORS with strong evidence of money laundering (${spadeRisk}% risk).`);
    }

    // Marlowe - Bridge tracking
    if (detectives.marlowe_bridge_tracking?.analysis) {
      findings.push("🔍 Philip Marlowe detected SUSPICIOUS cross-chain bridge activity consistent with evasion tactics.");
    }

    // Dupin - Compliance
    if (detectives.dupin_compliance_analysis?.compliance_report) {
      const complianceStatus = detectives.dupin_compliance_analysis.compliance_report.compliance_status;
      const amlRisk = detectives.dupin_compliance_analysis.compliance_report.key_findings?.aml_risk;
      if (complianceStatus === 'NON-COMPLIANT' && amlRisk === 'HIGH') {
        findings.push(`👤 Auguste Dupin found the wallet SEVERELY NON-COMPLIANT with HIGH AML RISK - immediate regulatory concern.`);
      } else {
        findings.push(`Auguste Dupin found the wallet ${typeof complianceStatus === 'string' ? complianceStatus.toLowerCase() : String(complianceStatus || 'unknown').toLowerCase()}.`);
      }
    }

    // Shadow - Network intelligence
    if (detectives.shadow_network_intelligence?.analysis) {
      const shadowRisk = detectives.shadow_network_intelligence.risk_score || 0;
      if (shadowRisk >= 0.8) {
        findings.push("🌙 The Shadow revealed SOPHISTICATED CRIMINAL NETWORK patterns indicating organized illegal operations.");
      } else {
        findings.push("The Shadow revealed sophisticated network patterns indicating organized activity.");
      }
    }

    // Raven - Final synthesis
    if (detectives.raven_communication?.final_truth_report?.analysis) {
      try {
        const ravenAnalysis = JSON.parse(detectives.raven_communication.final_truth_report.analysis);
        if (ravenAnalysis.risk_score) {
          const ravenRisk = Math.round(ravenAnalysis.risk_score * 100);
          if (ravenRisk >= 80) {
            findings.push(`🐦‍⬛ The Raven synthesized all findings with ${ravenRisk}% CERTAINTY of CRIMINAL ACTIVITY - evidence is overwhelming.`);
          } else {
            findings.push(`The Raven synthesized all findings with ${ravenRisk}% certainty of suspicious activity.`);
          }
        }
      } catch (e) {
        // If analysis is not JSON, skip Raven findings
        console.log('Raven analysis is not valid JSON:', e);
      }
    }

    if (findings.length > 0) {
      baseExplanation += " Key findings: " + findings.join(" ");
    } else {
      baseExplanation += " The investigation found standard transaction patterns with no major red flags.";
    }

    // Add threat classification if available
    if (consensusData.threat_classification) {
      if (isCritical) {
        baseExplanation += ` 🚨 THREAT LEVEL: ${consensusData.threat_classification}`;
      } else {
        baseExplanation += ` Classification: ${consensusData.threat_classification}.`;
      }
    }

    return baseExplanation;
  };

  // Function to get detective icon
  const getDetectiveIcon = (detective) => {
    const icons = {
      'poirot': '🕵️',
      'marple': '👵',
      'spade': '🚬',
      'marlowe': '🔍',
      'dupin': '👤',
      'shadow': '🌙',
      'raven': '🐦‍⬛'
    };
    return icons[detective] || '🔍';
  };

  useEffect(() => {
    // Obter dados da investigação
    const wallet = searchParams.get('wallet') || location.state?.walletAddress || '';
    setWalletAddress(wallet);

    if (!wallet) {
      navigate('/');
      return;
    }

    // Verificar se temos resultados do state (vindos da página de análise)
    if (location.state?.investigationResults) {
      console.log('📊 Investigation results from state:', location.state.investigationResults);
      setResults(location.state.investigationResults);
      setLoading(false);
    } else if (location.state?.error) {
      setError(location.state.error);
      setLoading(false);
    } else {
      // Se não temos resultados, fazer nova requisição
      performInvestigation(wallet);
    }
  }, [location, navigate, searchParams]);

  const performInvestigation = async (wallet) => {
    try {
      setLoading(true);

      const result = await legendarySquadService.investigate(wallet, 'comprehensive');
      console.log('📊 Investigation result from API:', result);
      setResults(result);
      setLoading(false);
    } catch (error) {
      console.error('Erro na investigação:', error);
      setError('Falha ao carregar resultados da investigação. Tente novamente.');
      setLoading(false);
    }
  };

  const getRiskColor = (riskLevel) => {
    switch (riskLevel?.toUpperCase()) {
      case 'HIGH': return 'text-red-400 bg-red-500/20 border-red-500/30';
      case 'MEDIUM': return 'text-yellow-400 bg-yellow-500/20 border-yellow-500/30';
      case 'LOW': return 'text-green-400 bg-green-500/20 border-green-500/30';
      default: return 'text-gray-400 bg-gray-500/20 border-gray-500/30';
    }
  };

  const getRiskEmoji = (riskLevel) => {
    switch (riskLevel?.toUpperCase()) {
      case 'HIGH': return '🚨';
      case 'MEDIUM': return '⚠️';
      case 'LOW': return '✅';
      default: return '❓';
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-purple-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-4 border-blue-500 border-t-transparent mx-auto mb-4"></div>
          <p className="text-white text-lg">Carregando resultados...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-red-900 to-purple-900 flex items-center justify-center p-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="max-w-2xl w-full text-center"
        >
          <div className="bg-red-500/20 border border-red-500/30 rounded-xl p-8">
            <div className="text-6xl mb-4">❌</div>
            <h1 className="text-2xl font-bold text-red-400 mb-4">Erro na Investigação</h1>
            <p className="text-gray-300 mb-6">{error}</p>
            <button
              onClick={() => navigate('/')}
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg transition-colors"
            >
              Voltar ao Início
            </button>
          </div>
        </motion.div>
      </div>
    );
  }

  if (!results || (results.status !== 'investigation_complete' && !results.success)) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-red-900 to-purple-900 flex items-center justify-center p-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="max-w-2xl w-full text-center"
        >
          <div className="bg-red-500/20 border border-red-500/30 rounded-xl p-8">
            <div className="text-6xl mb-4">⚠️</div>
            <h1 className="text-2xl font-bold text-red-400 mb-4">Investigação Incompleta</h1>
            <p className="text-gray-300 mb-6">
              Não foi possível completar a investigação desta carteira.
            </p>
            <div className="text-sm text-gray-400 mb-6">
              Debug: {JSON.stringify(results, null, 2)}
            </div>
            <button
              onClick={() => navigate('/')}
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg transition-colors"
            >
              Try New Investigation
            </button>
          </div>
        </motion.div>
      </div>
    );
  }

  // Extract main data - handle legendary squad structure correctly
  const legendaryResults = results.legendary_results || results;

  // Debug logs to see what we're getting
  console.log('🔍 Full results object:', results);
  console.log('🔍 Legendary results:', legendaryResults);

  // Use legendary_consensus instead of risk_assessment (which doesn't exist)
  const consensusData = legendaryResults.legendary_consensus || {};
  const riskLevel = consensusData.consensus_risk_level || 'UNKNOWN';
  const riskScore = consensusData.consensus_risk_score || 0;
  const confidence = consensusData.investigation_confidence || 'Unknown';

  console.log('🔍 Consensus data:', consensusData);

  // Get detective findings from legendary squad (including Raven communication)
  const detectives = {
    ...(legendaryResults.detective_findings || {}),
    ...(legendaryResults.raven_communication ? { raven_communication: legendaryResults.raven_communication } : {})
  };

  console.log('🔍 Extracted values:', { riskLevel, riskScore, confidence, detectives });

  // Generate simple explanation from detective findings
  const explanation = generateSimpleExplanation(detectives, riskLevel, riskScore, consensusData);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-purple-900 p-4">
      <div className="max-w-4xl mx-auto">

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-8"
        >
          <h1 className="text-4xl font-bold text-white mb-2">
            📊 Investigation Report
          </h1>

          {/* Risk Override Indicator */}
          {consensusData.override_triggered && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.2 }}
              className="inline-flex items-center px-3 py-1 bg-red-900/30 border border-red-500/50 rounded-full text-red-400 text-xs font-semibold mb-2"
            >
              ⚠️ Risk Override Applied
            </motion.div>
          )}

          <p className="text-gray-300 text-sm break-all font-mono">
            {walletAddress}
          </p>
        </motion.div>

        {/* Alerta Crítico para casos HIGH RISK */}
        {(riskLevel === 'HIGH' || consensusData.threat_classification?.includes('CRITICAL') ||
          consensusData.threat_classification?.includes('BLACKLISTED') ||
          consensusData.threat_classification?.includes('MONEY LAUNDERING') ||
          consensusData.threat_classification?.includes('CRIMINAL NETWORK')) && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.05 }}
            className="mb-6"
          >
            <div className="bg-red-900/50 border-2 border-red-500 rounded-xl p-6 backdrop-blur-sm">
              <div className="flex items-center justify-center mb-4">
                <div className="text-4xl mr-3">🚨</div>
                <h3 className="text-2xl font-bold text-red-400">CRITICAL SECURITY ALERT</h3>
              </div>
              <div className="text-center">
                <p className="text-red-200 text-lg font-semibold mb-2">
                  ⚠️ This wallet address has been flagged for high-risk activities
                </p>
                {consensusData.threat_classification?.includes('BLACKLISTED') && (
                  <p className="text-red-300 mb-2">
                    📋 <strong>BLACKLISTED:</strong> This address appears on known scam/fraud databases
                  </p>
                )}
                {consensusData.threat_classification?.includes('MONEY LAUNDERING') && (
                  <p className="text-red-300 mb-2">
                    💰 <strong>MONEY LAUNDERING:</strong> Sophisticated laundering patterns detected
                  </p>
                )}
                {consensusData.threat_classification?.includes('CRIMINAL NETWORK') && (
                  <p className="text-red-300 mb-2">
                    🕸️ <strong>CRIMINAL NETWORK:</strong> Connected to organized criminal operations
                  </p>
                )}
                <div className="mt-4 p-3 bg-red-800/30 rounded-lg">
                  <p className="text-red-100 text-sm">
                    <strong>⚠️ WARNING:</strong> Do NOT send funds to this address.
                    Report suspicious activity to relevant authorities.
                  </p>
                </div>
              </div>
            </div>
          </motion.div>
        )}

        {/* Resultado Principal */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.1 }}
          className="mb-8"
        >
          <div className={`rounded-xl p-6 border-2 ${getRiskColor(riskLevel)}`}>
            <div className="text-center">
              <div className="text-6xl mb-4">{getRiskEmoji(riskLevel)}</div>
              <h2 className="text-3xl font-bold mb-2">
                Risk Level: {riskLevel}
              </h2>
              <div className="text-2xl font-bold mb-4">
                Score: {Math.round(riskScore * 100)}/100
              </div>
            </div>
          </div>
        </motion.div>

        {/* AI Explanation */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.2 }}
          className="mb-8"
        >
          <div className="bg-gray-800/50 rounded-xl p-6 backdrop-blur-sm border border-gray-700">
            <h3 className="text-xl font-bold text-white mb-4 flex items-center">
              🧠 AI Explanation
            </h3>
            <div className="prose prose-invert max-w-none">
              <p className="text-gray-200 leading-relaxed text-lg">
                {explanation}
              </p>
            </div>
          </div>
        </motion.div>

        {/* Relatórios dos Detetives */}
        {Object.keys(detectives).length > 0 && (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
            className="mb-8"
          >
            <h3 className="text-2xl font-bold text-white mb-4 flex items-center">
              🕵️ Detective Reports
            </h3>
            <div className="grid gap-4">
              {Object.entries(detectives).map(([detective, report], index) => (
                <motion.div
                  key={detective}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.4 + index * 0.1 }}
                  className="bg-gray-800/30 rounded-lg p-4 border border-gray-700"
                >
                  <h4 className="font-bold text-blue-400 mb-2 capitalize">
                    {getDetectiveIcon(detective)} {detective.replace('_', ' ')}
                  </h4>
                  <div className="text-gray-300 text-sm">
                    {/* Show specific data based on detective type */}
                    {detective === 'poirot_transaction_analysis' && report.risk_score && (
                      <>
                        <div className="mb-2">
                          <strong>Risk Level:</strong> <span className={`px-2 py-1 rounded text-xs ${getRiskColor(report.risk_level)}`}>
                            {report.risk_level}
                          </span>
                        </div>
                        <div className="mb-2">
                          <strong>Risk Score:</strong> {Math.round(report.risk_score * 100)}%
                        </div>
                        {report.explanation && (
                          <div className="mb-2">
                            <strong>Analysis:</strong> {report.explanation.substring(0, 150)}...
                          </div>
                        )}
                      </>
                    )}

                    {detective === 'marple_pattern_detection' && report.summary_of_observations && (
                      <>
                        <div className="mb-2">
                          <strong>Overall Concern:</strong> <span className={`px-2 py-1 rounded text-xs ${
                            report.summary_of_observations.risk_evaluation?.overall_concern === 'High' ? 'bg-red-500/20 text-red-400' : 'bg-yellow-500/20 text-yellow-400'
                          }`}>
                            {report.summary_of_observations.risk_evaluation?.overall_concern || 'Unknown'}
                          </span>
                        </div>
                        <div className="mb-2">
                          <strong>Behavioral Assessment:</strong> {report.summary_of_observations.behavioral_assessment?.deceptive_practices ? 'Deceptive patterns detected' : 'Normal behavior'}
                        </div>
                        {report.summary_of_observations.risk_evaluation?.red_flags && Array.isArray(report.summary_of_observations.risk_evaluation.red_flags) && (
                          <div className="mb-2">
                            <strong>Red Flags:</strong>
                            <ul className="list-disc list-inside ml-2 mt-1">
                              {report.summary_of_observations.risk_evaluation.red_flags.slice(0, 3).map((flag, idx) => (
                                <li key={idx} className="text-red-400">{flag}</li>
                              ))}
                            </ul>
                          </div>
                        )}
                      </>
                    )}

                    {detective === 'spade_risk_assessment' && (
                      <>
                        <div className="mb-2">
                          <strong>Risk Score:</strong> {Math.round(report.risk_score * 100)}%
                        </div>
                        <div className="mb-2">
                          <strong>Confidence:</strong> {Math.round(report.confidence * 100)}%
                        </div>
                        {report.patterns && Array.isArray(report.patterns) && (
                          <div className="mb-2">
                            <strong>Patterns Detected:</strong>
                            <ul className="list-disc list-inside ml-2 mt-1">
                              {report.patterns.slice(0, 2).map((pattern, idx) => (
                                <li key={idx}>{pattern.pattern_type}</li>
                              ))}
                            </ul>
                          </div>
                        )}
                      </>
                    )}

                    {detective === 'dupin_compliance_analysis' && report.compliance_report && (
                      <>
                        <div className="mb-2">
                          <strong>Status:</strong> <span className={`px-2 py-1 rounded text-xs ${
                            report.compliance_report.compliance_status === 'NON-COMPLIANT' ? 'bg-red-500/20 text-red-400' : 'bg-green-500/20 text-green-400'
                          }`}>
                            {report.compliance_report.compliance_status}
                          </span>
                        </div>
                        <div className="mb-2">
                          <strong>AML Risk:</strong> {report.compliance_report.key_findings?.aml_risk}
                        </div>
                        {report.compliance_report.regulatory_flags && Array.isArray(report.compliance_report.regulatory_flags) && (
                          <div className="mb-2">
                            <strong>Regulatory Flags:</strong>
                            <ul className="list-disc list-inside ml-2 mt-1">
                              {report.compliance_report.regulatory_flags.map((flag, idx) => (
                                <li key={idx} className="text-yellow-400">{flag}</li>
                              ))}
                            </ul>
                          </div>
                        )}
                      </>
                    )}

                    {detective === 'raven_communication' && report.final_truth_report && (
                      <>
                        <div className="mb-2">
                          <strong>Synthesis Status:</strong> <span className="px-2 py-1 rounded text-xs bg-purple-500/20 text-purple-400">
                            {report.synthesis_status}
                          </span>
                        </div>
                        {(() => {
                          try {
                            const ravenAnalysis = JSON.parse(report.final_truth_report.analysis);
                            return (
                              <>
                                {ravenAnalysis.risk_score && (
                                  <div className="mb-2">
                                    <strong>Final Risk Score:</strong> {Math.round(ravenAnalysis.risk_score * 100)}%
                                  </div>
                                )}
                                {ravenAnalysis.reasoning && (
                                  <div className="mb-2">
                                    <strong>Final Reasoning:</strong> {ravenAnalysis.reasoning.substring(0, 150)}...
                                  </div>
                                )}
                              </>
                            );
                          } catch (e) {
                            return (
                              <div className="mb-2 text-gray-400">
                                <strong>Analysis:</strong> {report.final_truth_report.analysis ?
                                  report.final_truth_report.analysis.substring(0, 150) + '...' :
                                  'Analysis data not available'}
                              </div>
                            );
                          }
                        })()}
                        <div className="mb-2">
                          <strong>Explanation Quality:</strong> {report.explanation_quality}
                        </div>
                      </>
                    )}

                    {/* Generic fallback for other detectives */}
                    {!['poirot_transaction_analysis', 'marple_pattern_detection', 'spade_risk_assessment', 'dupin_compliance_analysis', 'raven_communication'].includes(detective) && (
                      <>
                        {report.risk_score && (
                          <div className="mb-2">
                            <strong>Risk Score:</strong> {Math.round(report.risk_score * 100)}%
                          </div>
                        )}
                        {report.reasoning && (
                          <div className="mb-2">
                            <strong>Analysis:</strong> {report.reasoning.substring(0, 150)}...
                          </div>
                        )}
                        {report.analysis && typeof report.analysis === 'string' && (
                          <div className="mb-2">
                            <strong>Findings:</strong> {report.analysis.substring(0, 150)}...
                          </div>
                        )}
                      </>
                    )}

                    {/* Confidence */}
                    {report.confidence && (
                      <div className="text-xs text-gray-500">
                        Confidence: {Math.round(report.confidence * 100)}%
                      </div>
                    )}
                  </div>
                </motion.div>
              ))}
            </div>
          </motion.div>
        )}

        {/* Risk Scoring Transparency Report */}
        {legendaryResults.transparency_report && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="mb-8"
          >
            <h3 className="text-2xl font-bold text-white mb-4 flex items-center">
              📊 Risk Scoring Transparency
            </h3>
            <div className="bg-gray-800/40 rounded-xl p-6 border border-gray-600">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">

                {/* Scoring Method */}
                <div className="bg-gray-700/30 rounded-lg p-4">
                  <h4 className="font-bold text-blue-400 mb-2">📋 Scoring Method</h4>
                  <p className="text-gray-300 text-sm mb-2">
                    <strong>System:</strong> {consensusData.scoring_methodology || 'Risk Scoring System v1.0'}
                  </p>
                  <p className="text-gray-300 text-sm mb-2">
                    <strong>Calculation:</strong> {legendaryResults.transparency_report.calculation_method}
                  </p>
                  {consensusData.override_triggered && (
                    <div className="mt-2 p-2 bg-red-900/30 rounded border border-red-500/30">
                      <p className="text-red-400 text-sm font-semibold">
                        ⚠️ <strong>Override Applied:</strong> {consensusData.override_reason?.join(', ')}
                      </p>
                    </div>
                  )}
                </div>

                {/* Top Contributors */}
                <div className="bg-gray-700/30 rounded-lg p-4">
                  <h4 className="font-bold text-blue-400 mb-2">🎯 Top Risk Contributors</h4>
                  {legendaryResults.transparency_report.top_contributors && (
                    <div className="space-y-1">
                      {legendaryResults.transparency_report.top_contributors.slice(0, 3).map(([agent, score], idx) => (
                        <div key={idx} className="flex justify-between text-sm">
                          <span className="text-gray-300 capitalize">{agent.replace('_', ' ')}</span>
                          <span className="text-white font-mono">{(score * 100).toFixed(1)}%</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Critical Flags */}
                {legendaryResults.transparency_report.critical_flags_detected > 0 && (
                  <div className="bg-red-900/20 rounded-lg p-4 border border-red-500/30">
                    <h4 className="font-bold text-red-400 mb-2">🚨 Critical Flags</h4>
                    <p className="text-red-300 text-sm">
                      <strong>{legendaryResults.transparency_report.critical_flags_detected}</strong> critical security flags detected
                    </p>
                    <p className="text-red-200 text-xs mt-1">
                      These flags triggered enhanced risk scoring weights
                    </p>
                  </div>
                )}

                {/* Investigation Confidence */}
                <div className="bg-gray-700/30 rounded-lg p-4">
                  <h4 className="font-bold text-blue-400 mb-2">🎖️ Investigation Quality</h4>
                  <p className="text-gray-300 text-sm mb-1">
                    <strong>Confidence:</strong> {consensusData.investigation_confidence}
                  </p>
                  <p className="text-gray-300 text-sm mb-1">
                    <strong>Detective Consensus:</strong> {consensusData.detective_consensus}
                  </p>
                  <p className="text-gray-300 text-sm">
                    <strong>Completeness:</strong> {legendaryResults.squad_performance?.investigation_completeness}
                  </p>
                </div>

              </div>
            </div>
          </motion.div>
        )}

        {/* Metadados */}
        {results.case_metadata && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="mb-8"
          >
            <div className="bg-gray-800/20 rounded-lg p-4 text-center">
              <p className="text-gray-400 text-sm">
                Investigação ID: {results.case_metadata.case_id} •
                Duração: {results.case_metadata.total_duration_seconds?.toFixed(1) || 'N/A'}s •
                {new Date().toLocaleString('pt-BR')}
              </p>
            </div>
          </motion.div>
        )}

        {/* Botões de Ação */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="flex gap-4 justify-center"
        >
          <button
            onClick={() => navigate('/')}
            className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg transition-colors"
          >
            New Investigation
          </button>
          <button
            onClick={() => window.location.reload()}
            className="bg-gray-600 hover:bg-gray-700 text-white px-6 py-3 rounded-lg transition-colors"
          >
            Update Results
          </button>
        </motion.div>

      </div>
    </div>
  );
}
