import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { detectiveService } from '../services/detectiveAPI';
import BlockchainTravel from '../components/Loading/BlockchainTravel';
import websocketService, { useWebSocket } from '../services/websocketService';

export default function AnalysisPageSimple() {
  const location = useLocation();
  const navigate = useNavigate();
  const [progress, setProgress] = useState(0);
  const [currentPhase, setCurrentPhase] = useState('Starting investigation...');
  const [walletAddress, setWalletAddress] = useState('');
  const [isInvestigating, setIsInvestigating] = useState(false);
  const [realTimeUpdates, setRealTimeUpdates] = useState([]);

  // WebSocket integration for real-time updates
  const { connectionStatus, lastMessage, subscribe, unsubscribe } = useWebSocket();

  useEffect(() => {
    // Connect to WebSocket when component mounts
    websocketService.connect();

    return () => {
      websocketService.disconnect();
    };
  }, []);

  // Handle WebSocket messages
  useEffect(() => {
    if (lastMessage) {
      console.log('📨 Real-time update received:', lastMessage);

      if (lastMessage.type === 'investigation_update') {
        setRealTimeUpdates(prev => [...prev, {
          time: new Date().toLocaleTimeString(),
          phase: lastMessage.phase || 'Update',
          message: lastMessage.message || 'Investigation progress',
          data: lastMessage.data
        }]);

        if (lastMessage.progress) {
          setProgress(lastMessage.progress);
        }

        if (lastMessage.current_phase) {
          setCurrentPhase(lastMessage.current_phase);
        }
      }
    }
  }, [lastMessage]);

  useEffect(() => {
    // Get wallet address and investigation data from state
    const wallet = location.state?.walletAddress || '';
    const investigationData = location.state?.investigationData || null;
    const realTimeMode = location.state?.realTimeMode || false;
    const fallbackMode = location.state?.fallbackMode || false;

    setWalletAddress(wallet);

    if (!wallet) {
      // If no wallet, redirect to home
      navigate('/');
      return;
    }

    // Start investigation based on mode
    if (realTimeMode && investigationData) {
      // REAL-TIME MODE: Show actual investigation progress
      performRealTimeTracking(wallet, investigationData);
    } else if (fallbackMode) {
      // FALLBACK MODE: Basic Solana RPC investigation
      performFallbackInvestigation(wallet);
    } else {
      // DEFAULT MODE: Start new investigation
      performRealTimeInvestigation(wallet);
    }
  }, [location, navigate]);

  // Function to track real-time investigation already started
  const performRealTimeTracking = async (wallet, investigationId, initialData) => {
    setIsInvestigating(true);
    setCurrentPhase('🔍 Real investigation in progress...');

    try {
      // Add initial update based on REAL data
      const initialUpdate = {
        phase: 'Investigation Started',
        message: `Coordinated swarm investigation for ${wallet}`,
        timestamp: new Date().toISOString(),
        agents_involved: initialData.agents_involved || []
      };
      setRealTimeUpdates([initialUpdate]);

      // Process REAL investigation steps from API
      let currentProgress = 10;
      const steps = initialData.investigation_steps || [];

      for (let i = 0; i < steps.length; i++) {
        const step = steps[i];
        currentProgress = Math.min(90, (i + 1) * (80 / steps.length) + 10);

        setProgress(currentProgress);

        // Use REAL agent data
        setCurrentPhase(`${step.agent_name} - ${step.specialty}`);

        // Create update based on REAL findings
        const update = {
          phase: step.agent_name,
          message: step.status === 'error'
            ? `${step.agent_name}: ${step.findings?.error || 'Investigation error'}`
            : `${step.agent_name}: Analysis completed - ${step.specialty}`,
          timestamp: step.timestamp,
          status: step.status
        };

        setRealTimeUpdates(prev => [...prev, update]);
        await new Promise(resolve => setTimeout(resolve, 1500));
      }

      // Final completion with REAL results
      setProgress(100);
      setCurrentPhase(initialData.final_report?.execution_summary?.completion_rate > 0
        ? 'Investigation completed successfully'
        : 'Investigation completed with issues');

      const finalUpdate = {
        phase: 'Final Report',
        message: `Investigation complete. Risk assessment: ${initialData.risk_assessment}`,
        timestamp: new Date().toISOString(),
        confidence_score: initialData.confidence_score
      };
      setRealTimeUpdates(prev => [...prev, finalUpdate]);

      // Navigate to results
      setTimeout(() => {
        navigate('/results-simple', {
          state: {
            walletAddress: wallet,
            investigationData: initialData,
            realTimeMode: true
          }
        });
      }, 2000);

    } catch (error) {
      console.error('Real-time tracking failed:', error);
      performFallbackInvestigation(wallet);
    }
  };

  // Function to perform real-time investigation with progress updates
  const performRealTimeInvestigation = async (wallet) => {
    setIsInvestigating(true);
    setCurrentPhase('🚀 Starting A2A Coordinated Investigation...');
    setProgress(10);

    try {
      console.log('🔍 Starting A2A investigation for:', wallet);

      setRealTimeUpdates([{
        time: new Date().toLocaleTimeString(),
        phase: 'Investigation Start',
        message: 'Launching coordinated detective swarm via A2A protocol...'
      }]);

      // Start A2A investigation
      const response = await fetch('http://localhost:9100/swarm/investigate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ wallet_address: wallet })
      });

      if (!response.ok) {
        throw new Error(`A2A Investigation failed: ${response.status}`);
      }

      const investigationData = await response.json();

      if (!investigationData.success) {
        throw new Error('A2A Investigation was not successful');
      }

      // Show progress based on completed agents
      const totalAgents = investigationData.agents_involved?.length || 4;
      const completedAgents = investigationData.investigation_steps?.filter(step => step.status === 'completed')?.length || 0;

      const progressPercent = Math.min(95, (completedAgents / totalAgents) * 85 + 10);
      setProgress(progressPercent);
      setCurrentPhase(`🔍 Analysis complete: ${completedAgents}/${totalAgents} agents finished`);

      // Add real-time updates for each agent
      if (investigationData.investigation_steps) {
        investigationData.investigation_steps.forEach((step) => {
          setRealTimeUpdates(prev => [...prev, {
            time: new Date().toLocaleTimeString(),
            phase: `${step.agent_name}`,
            message: `${step.specialty} - ${step.status === 'completed' ? '✅ Analysis Complete' : '🔄 Processing'}`,
            agentId: step.agent_id,
            status: step.status
          }]);
        });
      }

      // Final completion
      setProgress(100);
      setCurrentPhase('✅ Investigation Complete! Preparing results...');

      setRealTimeUpdates(prev => [...prev, {
        time: new Date().toLocaleTimeString(),
        phase: 'Investigation Complete',
        message: `Risk Assessment: ${investigationData.risk_assessment} | Confidence: ${Math.round((investigationData.confidence_score || 0) * 100)}%`
      }]);

      // Wait a moment to show completion, then navigate
      setTimeout(() => {
        navigate('/results-simple', {
          state: {
            walletAddress: wallet,
            investigationResults: investigationData,
            timestamp: new Date().toISOString()
          }
        });
      }, 3000);

    } catch (error) {
      console.error('A2A Investigation failed:', error);
      setCurrentPhase('❌ Investigation failed - trying fallback...');

      setRealTimeUpdates(prev => [...prev, {
        time: new Date().toLocaleTimeString(),
        phase: 'Error',
        message: `A2A error: ${error.message}. Switching to basic analysis...`
      }]);

      // Fallback to basic investigation
      setTimeout(() => {
        performFallbackInvestigation(wallet);
      }, 2000);
    } finally {
      setIsInvestigating(false);
    }
  };

  // Fallback investigation when real API fails
  const performFallbackInvestigation = async (wallet) => {
    setIsInvestigating(true);
    setCurrentPhase('Performing basic blockchain analysis...');

    try {
      setRealTimeUpdates(prev => [...prev, {
        time: new Date().toLocaleTimeString(),
        phase: 'Fallback Analysis',
        message: 'Main API unavailable, using direct Solana RPC...'
      }]);

      setProgress(20);
      setCurrentPhase('Connecting to Solana mainnet...');

      // Try basic Solana RPC call
      const basicData = await fetchBasicWalletData(wallet);

      setProgress(80);
      setCurrentPhase('Processing wallet data...');

      setRealTimeUpdates(prev => [...prev, {
        time: new Date().toLocaleTimeString(),
        phase: 'Data Retrieved',
        message: `Balance: ${basicData.balance_sol || 0} SOL`
      }]);

      setProgress(100);
      setCurrentPhase('Basic analysis completed');

      const finalUpdate = {
        time: new Date().toLocaleTimeString(),
        phase: 'Analysis Complete',
        message: 'Basic wallet data retrieved successfully'
      };
      setRealTimeUpdates(prev => [...prev, finalUpdate]);

      setTimeout(() => {
        navigate('/results-simple', {
          state: {
            walletAddress: wallet,
            investigationData: basicData,
            fallbackMode: true
          }
        });
      }, 2000);

    } catch (error) {
      console.error('Fallback investigation failed:', error);
      setCurrentPhase('Unable to analyze wallet');

      setRealTimeUpdates(prev => [...prev, {
        time: new Date().toLocaleTimeString(),
        phase: 'Error',
        message: `Analysis failed: ${error.message}`
      }]);

      setTimeout(() => {
        navigate('/results-simple', {
          state: {
            walletAddress: wallet,
            investigationError: error.message,
            fallbackMode: true
          }
        });
      }, 3000);
    } finally {
      setIsInvestigating(false);
    }
  };

  // Basic wallet data fetch for fallback
  const fetchBasicWalletData = async (wallet) => {
    try {
      const response = await fetch('https://api.mainnet-beta.solana.com', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'getBalance',
          params: [wallet]
        })
      });

      const data = await response.json();
      const balance = data.result?.value || 0;

      return {
        wallet_address: wallet,
        balance_sol: balance / 1000000000,
        balance_lamports: balance,
        data_source: 'solana_rpc_fallback',
        analysis_type: 'basic',
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        wallet_address: wallet,
        error: 'Unable to fetch wallet data',
        data_source: 'fallback_failed'
      };
    }
  };

  return (
    <div className="min-h-screen bg-navy text-white font-inter relative overflow-hidden">
      {/* Blockchain Travel Background - Viagem Espacial na Blockchain */}
      <div className="absolute inset-0 z-0">
        <BlockchainTravel />
      </div>

      {/* Dark Overlay for text readability */}
      <div className="absolute inset-0 bg-navy/60 backdrop-blur-[2px] z-10" />

      <div className="relative z-20 flex flex-col items-center justify-center min-h-screen px-4">
        <div className="w-full max-w-4xl mx-auto space-y-6">

          {/* Header - Viagem na Blockchain */}
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center space-y-4"
          >
            <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
              � Traveling through Blockchain
            </h1>
            <p className="text-xl text-gray-200 drop-shadow-lg">
              AI analysis in progress...
            </p>
            <div className="text-sm text-blue-300 font-mono bg-black/30 rounded-lg px-4 py-2 backdrop-blur-sm">
              {walletAddress}
            </div>
          </motion.div>

          {/* Progress Section - Mais transparente para visualizar o background */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-black/40 backdrop-blur-md border border-blue-500/30 rounded-xl p-6 space-y-6 shadow-2xl"
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
                  transition={{ duration: 0.5 }}
                  style={{
                    boxShadow: '0 0 20px rgba(59, 130, 246, 0.5)'
                  }}
                />
              </div>
            </div>

            {/* Current Phase - Mais destaque */}
            <motion.div
              key={currentPhase}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              className="text-center space-y-3"
            >
              <div className="text-lg text-white font-medium drop-shadow-lg">
                {currentPhase}
              </div>
              {isInvestigating && (
                <div className="flex justify-center">
                  <div className="relative">
                    <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-400"></div>
                    <div className="absolute inset-0 animate-ping rounded-full h-8 w-8 border border-blue-400 opacity-20"></div>
                  </div>
                </div>
              )}
            </motion.div>
          </motion.div>

          {/* Real-time Updates - Logs da investigação */}
          {realTimeUpdates.length > 0 && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-black/50 backdrop-blur-md border border-green-500/30 rounded-xl p-6 space-y-4 max-h-80 overflow-y-auto shadow-2xl"
            >
              <h3 className="text-lg font-semibold text-green-300 mb-4 flex items-center">
                <span className="animate-pulse">🔍</span>
                <span className="ml-2">Investigation Log - Live Feed</span>
              </h3>
              <div className="space-y-3">
                {realTimeUpdates.map((update, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="flex items-start space-x-3 text-sm bg-black/20 rounded-lg p-3 border-l-4 border-blue-400"
                  >
                    <div className="text-blue-300 font-mono text-xs whitespace-nowrap pt-1 font-bold">
                      {update.time || new Date(update.timestamp).toLocaleTimeString()}
                    </div>
                    <div className="text-gray-200 flex-1">
                      <div className="font-medium text-white drop-shadow">{update.phase}</div>
                      <div className="text-gray-300 text-xs mt-1">{update.message}</div>
                    </div>
                    {update.progress && (
                      <div className="text-green-400 font-mono text-xs font-bold">
                        {update.progress}%
                      </div>
                    )}
                  </motion.div>
                ))}
              </div>
            </motion.div>
          )}

        </div>
      </div>
    </div>
  );
}
