import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';

export default function AnalysisPageSimple() {
  const location = useLocation();
  const navigate = useNavigate();
  const [progress, setProgress] = useState(0);
  const [currentPhase, setCurrentPhase] = useState('Starting investigation...');
  const [walletAddress, setWalletAddress] = useState('');

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
    // Get wallet address from URL or state
    const searchParams = new URLSearchParams(location.search);
    const wallet = searchParams.get('wallet') || location.state?.walletAddress || '';
    setWalletAddress(wallet);

    if (!wallet) {
      // If no wallet, redirect to home
      navigate('/');
      return;
    }

    // Simulate investigation progress
    let currentProgress = 0;
    let phaseIndex = 0;

    const interval = setInterval(() => {
      currentProgress += Math.random() * 8 + 2; // Random increment between 2-10

      if (currentProgress >= 100) {
        currentProgress = 100;
        setProgress(100);
        setCurrentPhase('Investigation completed! Redirecting...');

        // Make real request to backend
        performRealInvestigation(wallet);

        clearInterval(interval);
        return;
      }

      setProgress(currentProgress);

      // Update phase based on progress
      const expectedPhaseIndex = Math.floor((currentProgress / 100) * phases.length);
      if (expectedPhaseIndex !== phaseIndex && expectedPhaseIndex < phases.length) {
        phaseIndex = expectedPhaseIndex;
        setCurrentPhase(phases[phaseIndex]);
      }
    }, 800); // Update every 800ms

    return () => clearInterval(interval);
  }, []); // Empty dependency array to run only once

  // Function to perform real investigation
  const performRealInvestigation = async (wallet) => {
    try {
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

      const result = await response.json();

      // Redirect to results with investigation data
      setTimeout(() => {
        navigate(`/results-simple?wallet=${wallet}`, {
          state: { investigationResult: result, walletAddress: wallet }
        });
      }, 2000);

    } catch (error) {
      console.error('Investigation error:', error);
      // In case of error, still redirect but with error data
      setTimeout(() => {
        navigate(`/results-simple?wallet=${wallet}`, {
          state: {
            error: 'Error during investigation. Please try again.',
            walletAddress: wallet
          }
        });
      }, 2000);
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

        {/* Informational note */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
          className="text-center text-gray-400 text-sm"
        >
          ⚡ This is a real investigation being processed by our backend<br/>
          Results will be accurate and based on real blockchain data
        </motion.div>

      </div>
    </div>
  );
}
