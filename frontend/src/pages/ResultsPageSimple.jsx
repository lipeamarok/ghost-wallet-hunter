import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate, useSearchParams } from 'react-router-dom';
import { motion } from 'framer-motion';

export default function ResultsPageSimple() {
  const location = useLocation();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [loading, setLoading] = useState(true);
  const [results, setResults] = useState(null);
  const [error, setError] = useState(null);
  const [walletAddress, setWalletAddress] = useState('');

  // Function to generate simple explanation from detective findings
  const generateSimpleExplanation = (detectives, riskLevel, riskScore) => {
    if (!detectives || Object.keys(detectives).length === 0) {
      return 'Analysis completed but explanation not available.';
    }

    const confidencePercent = Math.round(riskScore * 100);

    let baseExplanation = `Based on analysis by our AI detective squad, this wallet shows a ${riskLevel.toLowerCase()} risk level with ${confidencePercent}% confidence.`;

    // Add specific findings
    const findings = [];
    if (detectives.poirot?.explanation) {
      findings.push("Behavioral analysis reveals suspicious transaction patterns.");
    }
    if (detectives.marple?.patterns?.length > 0) {
      findings.push(`${detectives.marple.patterns.length} anomalous patterns detected.`);
    }
    if (detectives.spade?.patterns?.length > 0) {
      findings.push("Multiple high-risk indicators identified.");
    }

    if (findings.length > 0) {
      baseExplanation += " " + findings.join(" ");
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
    if (location.state?.investigationResult) {
      setResults(location.state.investigationResult);
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
      const response = await fetch(`${import.meta.env.VITE_API_URL || 'http://localhost:8001'}/api/v1/wallet/investigate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          wallet_address: wallet,
          investigation_type: 'comprehensive',
          notify_frontend: false
        })
      });

      if (!response.ok) {
        throw new Error(`Erro HTTP: ${response.status}`);
      }

      const result = await response.json();
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

  if (!results || !results.success) {
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

  // Extract main data - handle both nested and direct structure
  const actualResults = results.results || results; // Handle nested structure
  const riskAssessment = actualResults.risk_assessment || {};
  const riskLevel = riskAssessment.risk_level || 'UNKNOWN';
  const riskScore = riskAssessment.risk_score || 0;
  const confidence = riskAssessment.confidence || 0;

  // Get detective findings
  const detectives = actualResults.detective_findings || {};

  // Generate simple explanation from detective findings
  const explanation = generateSimpleExplanation(detectives, riskLevel, riskScore);

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
          <p className="text-gray-300 text-sm break-all font-mono">
            {walletAddress}
          </p>
        </motion.div>

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
                    {/* Risk Score */}
                    {report.risk_score && (
                      <div className="mb-2">
                        <strong>Risk Score:</strong> {Math.round(report.risk_score * 100)}%
                      </div>
                    )}

                    {/* Reasoning */}
                    {report.reasoning && (
                      <div className="mb-2">
                        <strong>Analysis:</strong> {report.reasoning.substring(0, 200)}...
                      </div>
                    )}

                    {/* Patterns */}
                    {report.patterns && Array.isArray(report.patterns) && (
                      <div className="mb-2">
                        <strong>Patterns:</strong>
                        <ul className="list-disc list-inside ml-2 mt-1">
                          {report.patterns.slice(0, 3).map((pattern, idx) => (
                            <li key={idx}>
                              {typeof pattern === 'string' ? pattern : pattern.description || 'Pattern detected'}
                            </li>
                          ))}
                        </ul>
                      </div>
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
