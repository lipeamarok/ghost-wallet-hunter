import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { MagnifyingGlassIcon } from '@heroicons/react/24/outline';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import ExampleAddress from './ExampleAddress';

export default function WalletInput() {
  const [inputValue, setInputValue] = useState('');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const navigate = useNavigate();

  const validateSolanaAddress = (address) => {
    // Solana address validation (32-44 characters, base58)
    const solanaRegex = /^[1-9A-HJ-NP-Za-km-z]{32,44}$/;
    return solanaRegex.test(address);
  };

  const handleAnalyze = () => {
    if (!inputValue.trim()) {
      toast.error('Please enter a Solana wallet address');
      return;
    }

    if (!validateSolanaAddress(inputValue.trim())) {
      toast.error('Invalid Solana wallet address format');
      return;
    }

    // Navigate directly to simple analysis page
    navigate(`/analysis-simple?wallet=${inputValue.trim()}`);
  };

  const handleExampleSelect = (address) => {
    setInputValue(address);
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 1.0, duration: 0.8 }}
      className="w-full max-w-2xl mx-auto space-y-4"
    >
      {/* Caixa de Input */}
      <div className="bg-white/5 backdrop-blur-lg border border-white/10 rounded-xl p-6 shadow-2xl">
        <div className="flex flex-col sm:flex-row gap-3">
          {/* Input Field */}
          <div className="flex-1">
            <input
              type="text"
              placeholder="Enter Solana wallet address to investigate..."
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleAnalyze()}
              className="w-full px-4 py-3 text-base bg-white/10 border border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-accent focus:border-transparent transition-all duration-300 placeholder-gray-400"
            />
          </div>

          {/* Investigate Button */}
          <div className="flex gap-2">
            <motion.button
              onClick={handleAnalyze}
              disabled={isAnalyzing}
              className="px-6 py-3 bg-gradient-to-r from-blue-accent to-green-safe text-white font-semibold rounded-lg flex items-center justify-center space-x-2 shadow-lg disabled:opacity-50 disabled:cursor-not-allowed hover:shadow-xl transition-all duration-300 min-w-[140px]"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              transition={{ duration: 0.2 }}
            >
              {isAnalyzing ? (
                <>
                  <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span className="hidden sm:inline">Investigating...</span>
                </>
              ) : (
                <>
                  <MagnifyingGlassIcon className="w-5 h-5" />
                  <span className="hidden sm:inline">Investigate</span>
                </>
              )}
            </motion.button>
          </div>
        </div>
      </div>

      {/* Exemplo abaixo da caixa */}
      <div className="text-center">
        <ExampleAddress onAddressSelect={handleExampleSelect} />
      </div>
    </motion.div>
  );
}
