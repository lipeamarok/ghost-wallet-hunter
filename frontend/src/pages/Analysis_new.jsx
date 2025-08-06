// src/pages/Analysis.jsx
import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import ArrivalTransition from '../components/Transitions/ArrivalTransition';
import { getRealAIInvestigateUrl } from '../config/api';

export default function Analysis() {
  const location = useLocation();
  const navigate = useNavigate();
  const [walletAddress, setWalletAddress] = useState('');
  const [currentPhase, setCurrentPhase] = useState('Initializing investigation...');
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    // Get wallet address from navigation state
    const wallet = location.state?.walletAddress || '';
    setWalletAddress(wallet);

    if (!wallet) {
      navigate('/');
      return;
    }

    // Start investigation immediately
    startInvestigation(wallet);
  }, [location, navigate]);

  const startInvestigation = async (wallet) => {
    try {
      setCurrentPhase('🚀 Starting AI investigation...');
      setProgress(10);

      // Chamada para API do backend (Produção Render)
      const response = await fetch(getRealAIInvestigateUrl(), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          wallet_address: wallet,
          investigation_type: 'comprehensive',
        }),
      });

      setProgress(30);
      setCurrentPhase('🔍 Analyzing blockchain data...');

      if (response.ok) {
        const investigationData = await response.json();
        
        setProgress(60);
        setCurrentPhase('🧠 Processing AI analysis...');

        // Simulate processing time
        await new Promise(resolve => setTimeout(resolve, 2000));

        setProgress(90);
        setCurrentPhase('✅ Investigation completed!');

        // Wait a moment then navigate to results
        setTimeout(() => {
          navigate('/results', {
            state: {
              walletAddress: wallet,
              investigationData: investigationData,
              timestamp: new Date().toISOString()
            }
          });
        }, 1500);

      } else {
        throw new Error('Investigation API failed');
      }

    } catch (error) {
      console.error('Investigation failed:', error);
      setCurrentPhase('❌ Investigation failed, using fallback...');
      
      // Navigate to results with error state
      setTimeout(() => {
        navigate('/results', {
          state: {
            walletAddress: wallet,
            investigationError: error.message,
            fallbackMode: true
          }
        });
      }, 2000);
    }
  };

  return (
    <div className="min-h-screen bg-navy text-white relative overflow-hidden">
      {/* Arrival Transition Background - Looping Animation */}
      <div className="absolute inset-0 z-0">
        <ArrivalTransition />
      </div>

      {/* Dark Overlay for text readability */}
      <div className="absolute inset-0 bg-navy/40 backdrop-blur-[1px] z-10" />

      {/* Content Overlay */}
      <div className="relative z-20 flex flex-col items-center justify-center min-h-screen px-4">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center space-y-8 max-w-2xl"
        >
          {/* Title */}
          <motion.h1
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-5xl font-bold bg-gradient-to-r from-blue-400 via-purple-400 to-green-400 bg-clip-text text-transparent drop-shadow-2xl"
          >
            🌌 Traveling Through Blockchain
          </motion.h1>

          {/* Wallet Address */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="text-sm text-blue-300 font-mono bg-black/50 rounded-lg px-6 py-3 backdrop-blur-sm border border-blue-500/30"
          >
            {walletAddress}
          </motion.div>

          {/* Progress */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1 }}
            className="bg-black/50 backdrop-blur-md border border-blue-500/30 rounded-xl p-6 space-y-4 shadow-2xl"
          >
            {/* Progress Bar */}
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-200 font-medium">Investigation Progress</span>
                <span className="text-blue-300 font-mono font-bold">{Math.round(progress)}%</span>
              </div>
              <div className="w-full bg-gray-800/60 rounded-full h-3 overflow-hidden border border-gray-600/50">
                <motion.div
                  className="h-full bg-gradient-to-r from-blue-400 via-purple-400 to-green-400 rounded-full shadow-lg"
                  initial={{ width: 0 }}
                  animate={{ width: `${progress}%` }}
                  transition={{ duration: 0.8 }}
                  style={{
                    boxShadow: '0 0 20px rgba(59, 130, 246, 0.5)'
                  }}
                />
              </div>
            </div>

            {/* Current Phase */}
            <motion.div
              key={currentPhase}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              className="text-center space-y-3"
            >
              <div className="text-lg text-white font-medium drop-shadow-lg">
                {currentPhase}
              </div>
              <div className="flex justify-center">
                <div className="relative">
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-400"></div>
                  <div className="absolute inset-0 animate-ping rounded-full h-8 w-8 border border-blue-400 opacity-20"></div>
                </div>
              </div>
            </motion.div>
          </motion.div>

          {/* AI Processing Text */}
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.5 }}
            className="text-gray-300 text-lg drop-shadow-lg"
          >
            AI detectives are analyzing your wallet...
          </motion.p>
        </motion.div>
      </div>
    </div>
  );
}
