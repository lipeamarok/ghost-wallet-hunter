import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { legendarySquadService } from '../services/detectiveAPI';

export default function AnalysisPageSimple() {
  const location = useLocation();
  const navigate = useNavigate();
  const [progress, setProgress] = useState(0);
  const [currentPhase, setCurrentPhase] = useState('Starting investigation...');
  const [walletAddress, setWalletAddress] = useState('');
  const [isInvestigating, setIsInvestigating] = useState(false);
  const [realTimeUpdates, setRealTimeUpdates] = useState([]);

  // Investigation phases
  const phases = [
    'Validating wallet address...',
    'Connecting to Solana blockchain...',
    'Collecting transactions...',
    'Analyzing suspicious patterns...',
    'Activating AI detective squad...',
    'Poirot investigating behaviors...',
    'Marlowe analyzing clusters...',
    'Marple detecting anomalies...',
    'Dupin checking blacklists...',
    'Spade tracking connections...',
    'Raven analyzing timing patterns...',
    'Shadow investigating money laundering...',
    'Consolidating final report...',
    'Generating simple explanation...'
  ];

  useEffect(() => {
    // Get wallet address from state or URL
    const searchParams = new URLSearchParams(location.search);
    const wallet = searchParams.get('wallet') || location.state?.walletAddress || '';

    setWalletAddress(wallet);

    if (!wallet) {
      // If no wallet, redirect to home
      navigate('/');
      return;
    }

    // Start real investigation immediately
    performRealTimeInvestigation(wallet);
  }, [location, navigate]);

  // Function to perform real-time investigation with progress updates
  const performRealTimeInvestigation = async (wallet) => {
    setIsInvestigating(true);

    // Start progress simulation
    let currentProgress = 0;
    let phaseIndex = 0;

    const progressInterval = setInterval(() => {
      currentProgress += Math.random() * 3 + 1; // Slower increment for real investigation

      if (currentProgress >= 95) {
        currentProgress = 95; // Stop at 95% until real API completes
      }

      setProgress(currentProgress);

      // Update phase based on progress
      const expectedPhaseIndex = Math.floor((currentProgress / 100) * phases.length);
      if (expectedPhaseIndex !== phaseIndex && expectedPhaseIndex < phases.length) {
        phaseIndex = expectedPhaseIndex;
        setCurrentPhase(phases[phaseIndex]);

        // Add real-time update
        setRealTimeUpdates(prev => [...prev, {
          time: new Date().toLocaleTimeString(),
          phase: phases[phaseIndex],
          progress: Math.round(currentProgress)
        }]);
      }
    }, 1000); // Update every second

    try {
      // Make real API call
      console.log('🔍 Starting real investigation for:', wallet);
      const investigationData = await legendarySquadService.investigate(wallet, 'comprehensive');

      // Investigation completed
      clearInterval(progressInterval);
      setProgress(100);
      setCurrentPhase('Investigation completed! Redirecting to results...');

      setRealTimeUpdates(prev => [...prev, {
        time: new Date().toLocaleTimeString(),
        phase: '✅ Investigation completed successfully!',
        progress: 100
      }]);

      // Redirect to results after a brief delay
      setTimeout(() => {
        navigate(`/results-simple?wallet=${wallet}`, {
          state: {
            investigationResults: investigationData,
            walletAddress: wallet
          }
        });
      }, 2000);

    } catch (error) {
      console.error('Investigation failed:', error);
      clearInterval(progressInterval);

      setCurrentPhase('❌ Investigation failed');
      setRealTimeUpdates(prev => [...prev, {
        time: new Date().toLocaleTimeString(),
        phase: `❌ Error: ${error.message}`,
        progress: Math.round(currentProgress)
      }]);

      // Redirect to results with error after delay
      setTimeout(() => {
        navigate(`/results-simple?wallet=${wallet}`, {
          state: {
            error: `Investigation failed: ${error.message}`,
            walletAddress: wallet
          }
        });
      }, 3000);
    } finally {
      setIsInvestigating(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-purple-900 flex items-center justify-center p-4">
      <div className="max-w-2xl w-full">

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-8"
        >
          <h1 className="text-4xl font-bold text-white mb-2">
            🔍 Investigation in Progress
          </h1>
          <p className="text-gray-300 text-lg">
            AI Detective Squad analyzing:
          </p>
          <p className="text-blue-400 font-mono text-sm mt-1 break-all">
            {walletAddress}
          </p>
        </motion.div>

        {/* Barra de Progresso */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.2 }}
          className="mb-8"
        >
          <div className="bg-gray-800/50 rounded-xl p-6 backdrop-blur-sm border border-gray-700">

            {/* Progress label */}
            <div className="flex justify-between items-center mb-4">
              <span className="text-gray-300">Progress</span>
              <span className="text-2xl font-bold text-blue-400">
                {Math.round(progress)}%
              </span>
            </div>

            {/* Progress bar */}
            <div className="w-full bg-gray-700 rounded-full h-4 overflow-hidden">
              <motion.div
                className="h-full bg-gradient-to-r from-blue-500 to-purple-500 rounded-full"
                initial={{ width: 0 }}
                animate={{ width: `${progress}%` }}
                transition={{ duration: 0.5, ease: "easeOut" }}
              />
            </div>

            {/* Current phase */}
            <motion.p
              key={currentPhase}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-center text-gray-200 mt-4 text-lg"
            >
              {currentPhase}
            </motion.p>
          </div>
        </motion.div>

        {/* Detective animation */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.4 }}
          className="grid grid-cols-4 gap-3 mb-6"
        >
          {['🕵️', '🔍', '🔎', '🕵️‍♀️', '🔬', '🧠', '⚡'].map((detective, index) => (
            <motion.div
              key={index}
              className="bg-gray-800/30 rounded-lg p-3 text-center"
              animate={{
                scale: progress > (index * 14) ? [1, 1.1, 1] : 1,
                opacity: progress > (index * 14) ? 1 : 0.5
              }}
              transition={{
                duration: 1,
                repeat: progress > (index * 14) ? Infinity : 0,
                repeatDelay: 1
              }}
            >
              <div className="text-2xl mb-1">{detective}</div>
              <div className="text-xs text-gray-400">
                {progress > (index * 14) ? 'Active' : 'Waiting'}
              </div>
            </motion.div>
          ))}
        </motion.div>

        {/* Real-time updates */}
        {realTimeUpdates.length > 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.8 }}
            className="bg-gray-800/30 rounded-xl p-4 backdrop-blur-sm border border-gray-700 mb-6"
          >
            <h3 className="text-white font-semibold mb-3 flex items-center">
              📋 Live Investigation Log
            </h3>
            <div className="space-y-2 max-h-40 overflow-y-auto">
              {realTimeUpdates.slice(-5).map((update, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  className="flex justify-between items-center text-sm"
                >
                  <span className="text-gray-300">{update.phase}</span>
                  <span className="text-blue-400 font-mono text-xs">
                    {update.time} ({update.progress}%)
                  </span>
                </motion.div>
              ))}
            </div>
          </motion.div>
        )}

        {/* Informational note */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
          className="text-center text-gray-400 text-sm"
        >
          ⚡ Live investigation in progress with real AI detectives<br/>
          {isInvestigating ?
            '🔄 Connecting to blockchain and analyzing patterns...' :
            '✅ Analysis complete - preparing results...'
          }
        </motion.div>

      </div>
    </div>
  );
}
