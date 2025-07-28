import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { MagnifyingGlassIcon, ArrowLeftIcon } from '@heroicons/react/24/outline';
import { useNavigate } from 'react-router-dom';
import { useWalletInvestigation } from '../hooks/useDetectiveAPI';
import useBlacklist from '../hooks/useBlacklist';
import TerminalAnalyzer from '../components/Terminal/TerminalAnalyzer';
import NetworkTopology from '../components/Visualization/NetworkTopology';
import IntelligencePanel from '../components/Intelligence/IntelligencePanel';
import Layout from '../components/Layout/Layout';

const AnalysisPage = () => {
  const [walletAddress, setWalletAddress] = useState('');
  const [blacklistResult, setBlacklistResult] = useState(null);
  const [currentPhase, setCurrentPhase] = useState(0);
  const [investigationComplete, setInvestigationComplete] = useState(false);
  const [showAnalysisComponents, setShowAnalysisComponents] = useState(true);
  const navigate = useNavigate();
  const { launchInvestigation, isInvestigating, error, result } = useWalletInvestigation();
  const { checkWallet, isChecking, stats } = useBlacklist();

  // Get wallet from URL parameters
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const walletParam = urlParams.get('wallet');
    if (walletParam) {
      setWalletAddress(walletParam);
      // Auto-start analysis if wallet is provided via URL
      handleAnalysis(null, walletParam);
    }
  }, []);

  const handleAnalysis = async (e, directWallet = null) => {
    if (e) e.preventDefault();

    const targetWallet = directWallet || walletAddress.trim();
    if (!targetWallet) {
      alert('Please enter a wallet address');
      return;
    }

    try {
      setCurrentPhase(0);
      setShowAnalysisComponents(true);
      console.log('Starting professional investigation for:', targetWallet);

      // Phase 0: Blacklist verification
      setCurrentPhase(0);
      const blacklistCheck = await checkWallet(targetWallet);
      setBlacklistResult(blacklistCheck?.data || null);

      if (blacklistCheck?.data?.is_blacklisted) {
        const confirmContinue = window.confirm(
          `SECURITY ALERT: This wallet is flagged in threat intelligence databases.\n\n` +
          `${blacklistCheck.data.warning}\n\n` +
          `Continue with full analysis?`
        );

        if (!confirmContinue) {
          return;
        }
      }

      // Phase 1: Transaction pattern analysis
      setTimeout(() => setCurrentPhase(1), 1000);

      // Phase 2: Network topology mapping
      setTimeout(() => setCurrentPhase(2), 2500);

      // Phase 3: Risk assessment calculation
      setTimeout(() => setCurrentPhase(3), 4000);

      // Phase 4: Generate intelligence report
      setTimeout(() => setCurrentPhase(4), 5500);

      // Launch full investigation
      const result = await launchInvestigation(targetWallet);

      setTimeout(() => {
        setInvestigationComplete(true);
        console.log('Investigation complete, navigating to professional results...');

        navigate('/results/' + encodeURIComponent(targetWallet), {
          state: {
            investigationData: result?.data || result,
            walletAddress: targetWallet,
            blacklistResult: blacklistResult,
            professionalMode: true,
            analysisData: {
              phases: currentPhase,
              components: showAnalysisComponents
            }
          }
        });
      }, 7000);

    } catch (error) {
      console.error('Investigation failed:', error);
      alert('Investigation failed. Please try again.');
    }
  };

  const handleBackToHome = () => {
    setShowAnalysisComponents(false);
    navigate('/');
  };

  return (
    <Layout>
      <div className="min-h-screen bg-black text-green-400">
        <div className="max-w-7xl mx-auto px-4 py-8">
          {!isInvestigating ? (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="max-w-4xl mx-auto"
            >
              <div className="bg-gray-900 border border-gray-700 rounded-lg p-8">
                <div className="flex items-center mb-6">
                  <button
                    onClick={handleBackToHome}
                    className="flex items-center text-cyan-400 hover:text-cyan-300 mr-4 transition-colors font-mono"
                  >
                    <ArrowLeftIcon className="w-5 h-5 mr-2" />
                    [BACK_TO_COMMAND]
                  </button>
                  <h2 className="text-xl font-mono font-bold text-cyan-400">
                    TARGET ACQUISITION INTERFACE
                  </h2>
                </div>

                <form onSubmit={handleAnalysis} className="space-y-6">
                  <div>
                    <label className="block text-sm font-mono text-gray-300 mb-3">
                      WALLET ADDRESS:
                    </label>
                    <div className="relative">
                      <input
                        type="text"
                        value={walletAddress}
                        onChange={(e) => setWalletAddress(e.target.value)}
                        placeholder="Enter target wallet address..."
                        className="w-full px-4 py-3 bg-black border border-gray-600 rounded text-green-400 font-mono focus:outline-none focus:border-cyan-400 transition-colors"
                        disabled={isInvestigating}
                      />
                      <MagnifyingGlassIcon className="absolute right-3 top-3 h-6 w-6 text-gray-500" />
                    </div>
                  </div>

                  <button
                    type="submit"
                    disabled={isInvestigating || !walletAddress.trim()}
                    className="w-full py-3 bg-cyan-600 hover:bg-cyan-500 disabled:bg-gray-600 text-black font-mono font-bold rounded transition-colors"
                  >
                    {isInvestigating ? 'INVESTIGATION IN PROGRESS...' : 'INITIATE INVESTIGATION'}
                  </button>
                </form>
              </div>
            </motion.div>
          ) : (
            <div className="space-y-8">
              {/* Keep analysis components visible with back option */}
              <div className="flex items-center justify-between mb-6">
                <button
                  onClick={handleBackToHome}
                  className="flex items-center text-cyan-400 hover:text-cyan-300 transition-colors font-mono"
                >
                  <ArrowLeftIcon className="w-5 h-5 mr-2" />
                  [RETURN_TO_COMMAND]
                </button>
                <div className="text-cyan-400 font-mono text-sm">
                  PHASE: {currentPhase}/4 | TARGET: {walletAddress.substring(0, 8)}...
                </div>
              </div>

              {/* Persistent Analysis Components Container */}
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: showAnalysisComponents ? 1 : 0.5 }}
                className="bg-gray-900 border border-gray-700 rounded-lg p-6"
              >
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-mono font-bold text-cyan-400">
                    [BLOCKCHAIN_INTELLIGENCE_REPORT]
                  </h3>
                  <div className="flex items-center space-x-4">
                    <button
                      onClick={() => setShowAnalysisComponents(!showAnalysisComponents)}
                      className="text-sm font-mono text-gray-400 hover:text-cyan-400 transition-colors"
                    >
                      {showAnalysisComponents ? '[MINIMIZE]' : '[EXPAND]'}
                    </button>
                    <div className={`w-3 h-3 rounded-full ${isInvestigating ? 'bg-yellow-400 animate-pulse' : 'bg-green-400'}`}></div>
                  </div>
                </div>

                {showAnalysisComponents && (
                  <div className="space-y-6">
                    <TerminalAnalyzer
                      walletAddress={walletAddress}
                      isAnalyzing={isInvestigating}
                      currentStep={currentPhase}
                    />

                    {currentPhase >= 2 && (
                      <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.5 }}
                      >
                        <div className="border-t border-gray-600 pt-6">
                          <h4 className="text-lg font-mono font-bold text-cyan-400 mb-4">
                            NETWORK TOPOLOGY ANALYSIS
                          </h4>
                          <NetworkTopology
                            walletAddress={walletAddress}
                            investigationData={result}
                            isAnalyzing={isInvestigating}
                            currentPhase={currentPhase}
                          />
                        </div>
                      </motion.div>
                    )}

                    {currentPhase >= 4 && (
                      <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 1 }}
                      >
                        <div className="border-t border-gray-600 pt-6">
                          <IntelligencePanel
                            investigationData={result}
                            walletAddress={walletAddress}
                            isAnalyzing={isInvestigating}
                            currentPhase={currentPhase}
                          />
                        </div>
                      </motion.div>
                    )}
                  </div>
                )}
              </motion.div>
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
};

export default AnalysisPage;
