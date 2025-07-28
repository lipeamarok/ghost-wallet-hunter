import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const TerminalAnalyzer = ({
  walletAddress,
  onAnalysisComplete,
  isAnalyzing,
  analysisSteps = [],
  currentStep = 0
}) => {
  const [displayText, setDisplayText] = useState('');
  const [currentLine, setCurrentLine] = useState(0);
  const [showCursor, setShowCursor] = useState(true);

  const terminalLines = [
    '> ghost-wallet-hunter:~$ analyze ' + (walletAddress || '[wallet_address]'),
    '  Initializing blockchain forensics toolkit...',
    '  Loading detection algorithms...',
    '  [████████████████████████████████████████████████████████] 100%',
    '',
    '  GHOST WALLET HUNTER v2.0 - Blockchain Intelligence Platform',
    '  Copyright (c) 2025 - Professional Forensics Division',
    '',
    '  Target: ' + (walletAddress || 'PENDING'),
    '  Protocol: Solana Network',
    '  Analysis Mode: Deep Investigation',
    '',
    '  [PHASE_0] Blacklist verification...........RUNNING',
  ];

  const analysisPhases = [
    { phase: 'PHASE_0', name: 'Blacklist verification', status: 'PENDING' },
    { phase: 'PHASE_1', name: 'Transaction pattern analysis', status: 'PENDING' },
    { phase: 'PHASE_2', name: 'Network topology mapping', status: 'PENDING' },
    { phase: 'PHASE_3', name: 'Risk assessment calculation', status: 'PENDING' },
    { phase: 'PHASE_4', name: 'Generating intelligence report', status: 'PENDING' },
  ];

  const [phases, setPhases] = useState(analysisPhases);

  // Cursor blinking effect
  useEffect(() => {
    const interval = setInterval(() => {
      setShowCursor(prev => !prev);
    }, 530);
    return () => clearInterval(interval);
  }, []);

  // Terminal text reveal effect
  useEffect(() => {
    if (isAnalyzing && currentLine < terminalLines.length) {
      const timer = setTimeout(() => {
        setCurrentLine(prev => prev + 1);
      }, 150);
      return () => clearTimeout(timer);
    }
  }, [currentLine, isAnalyzing, terminalLines.length]);

  // Phase progression
  useEffect(() => {
    if (isAnalyzing && currentStep < phases.length) {
      const timer = setTimeout(() => {
        setPhases(prev => prev.map((phase, index) => {
          if (index < currentStep) {
            return { ...phase, status: 'COMPLETE' };
          } else if (index === currentStep) {
            return { ...phase, status: 'RUNNING' };
          }
          return phase;
        }));
      }, 1000 + (currentStep * 800));
      return () => clearTimeout(timer);
    }
  }, [currentStep, isAnalyzing, phases.length]);

  const getStatusColor = (status) => {
    switch (status) {
      case 'COMPLETE': return 'text-green-400';
      case 'RUNNING': return 'text-cyan-400 animate-pulse';
      case 'ERROR': return 'text-red-400';
      default: return 'text-gray-500';
    }
  };

  const getStatusSymbol = (status) => {
    switch (status) {
      case 'COMPLETE': return '✓';
      case 'RUNNING': return '⚡';
      case 'ERROR': return '✗';
      default: return '○';
    }
  };

  return (
    <div className="bg-black border border-gray-800 rounded-lg overflow-hidden font-mono text-sm">
      {/* Terminal Header */}
      <div className="bg-gray-900 px-4 py-2 flex items-center justify-between border-b border-gray-800">
        <div className="flex items-center space-x-2">
          <div className="w-3 h-3 bg-red-500 rounded-full"></div>
          <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
          <div className="w-3 h-3 bg-green-500 rounded-full"></div>
        </div>
        <div className="text-gray-400 text-xs">ghost-wallet-hunter-terminal</div>
      </div>

      {/* Terminal Content */}
      <div className="p-4 min-h-[400px] bg-black text-green-400">
        {/* Initial Terminal Output */}
        <AnimatePresence>
          {terminalLines.slice(0, currentLine).map((line, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.1 }}
              className="mb-1"
            >
              {line}
            </motion.div>
          ))}
        </AnimatePresence>

        {/* Analysis Phases */}
        {isAnalyzing && currentLine >= terminalLines.length && (
          <div className="mt-4 space-y-2">
            {phases.map((phase, index) => (
              <motion.div
                key={phase.phase}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.2 }}
                className="flex items-center justify-between"
              >
                <span className="text-gray-300">
                  [{phase.phase}] {phase.name}
                  <span className="ml-2">
                    {'·'.repeat(40 - phase.name.length)}
                  </span>
                </span>
                <span className={`ml-2 font-bold ${getStatusColor(phase.status)}`}>
                  {getStatusSymbol(phase.status)} {phase.status}
                </span>
              </motion.div>
            ))}
          </div>
        )}

        {/* Active Cursor */}
        {showCursor && (
          <span className="text-green-400 bg-green-400 animate-pulse">█</span>
        )}

        {/* Scan Lines Effect */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute inset-0 bg-gradient-to-b from-transparent via-cyan-500/5 to-transparent animate-pulse"></div>
        </div>
      </div>
    </div>
  );
};

export default TerminalAnalyzer;
