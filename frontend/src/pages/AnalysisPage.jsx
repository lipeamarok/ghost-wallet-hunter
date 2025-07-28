import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useQuery } from 'react-query';
import toast from 'react-hot-toast';
import { ArrowLeftIcon } from '@heroicons/react/24/outline';

import LoadingSpinner from '../components/UI/LoadingSpinner';
import { analyzeWallet } from '../utils/api';

const AnalysisPage = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const walletAddress = searchParams.get('wallet');

  const [analysisSteps, setAnalysisSteps] = useState([
    { id: 1, name: 'Wallet Validation', status: 'pending', description: 'Verifying wallet address format' },
    { id: 2, name: 'Blockchain Scan', status: 'pending', description: 'Fetching transaction history' },
    { id: 3, name: 'AI Analysis', status: 'pending', description: 'JuliaOS AI processing patterns' },
    { id: 4, name: 'Risk Assessment', status: 'pending', description: 'Calculating risk scores' },
    { id: 5, name: 'Clustering', status: 'pending', description: 'Identifying wallet clusters' },
    { id: 6, name: 'Report Generation', status: 'pending', description: 'Compiling final analysis' },
  ]);

  const [currentStep, setCurrentStep] = useState(0);

  // React Query for wallet analysis
  const { data, isLoading, error, isError } = useQuery(
    ['walletAnalysis', walletAddress],
    () => analyzeWallet(walletAddress),
    {
      enabled: !!walletAddress,
      retry: 1,
      refetchOnWindowFocus: false,
      onError: (error) => {
        toast.error(error.message || 'Analysis failed');
      },
      onSuccess: (data) => {
        // Complete all steps
        setAnalysisSteps(prev => prev.map(step => ({ ...step, status: 'completed' })));
        setTimeout(() => {
          navigate(`/results/${walletAddress}`);
        }, 1500);
      }
    }
  );

  // Simulate step progression
  useEffect(() => {
    if (!isLoading || !walletAddress) return;

    const stepInterval = setInterval(() => {
      setCurrentStep(prev => {
        const nextStep = prev + 1;

        setAnalysisSteps(current =>
          current.map((step, index) => {
            if (index < nextStep) {
              return { ...step, status: 'completed' };
            } else if (index === nextStep) {
              return { ...step, status: 'processing' };
            }
            return step;
          })
        );

        if (nextStep >= analysisSteps.length) {
          clearInterval(stepInterval);
          return prev;
        }

        return nextStep;
      });
    }, 1500);

    return () => clearInterval(stepInterval);
  }, [isLoading, walletAddress, analysisSteps.length]);

  if (!walletAddress) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-white mb-4">No wallet address provided</h2>
          <button
            onClick={() => navigate('/')}
            className="px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
          >
            Go Back Home
          </button>
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center max-w-md">
          <div className="w-16 h-16 mx-auto mb-4 bg-red-500/20 rounded-full flex items-center justify-center">
            <span className="text-red-400 text-2xl">⚠️</span>
          </div>
          <h2 className="text-2xl font-bold text-white mb-4">Analysis Failed</h2>
          <p className="text-gray-300 mb-6">{error?.message || 'An unexpected error occurred'}</p>
          <div className="space-y-3">
            <button
              onClick={() => window.location.reload()}
              className="block w-full px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
            >
              Try Again
            </button>
            <button
              onClick={() => navigate('/')}
              className="block w-full px-6 py-3 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
            >
              Go Back Home
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen py-12">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8"
        >
          <button
            onClick={() => navigate('/')}
            className="flex items-center space-x-2 text-gray-400 hover:text-white transition-colors mb-6"
          >
            <ArrowLeftIcon className="w-5 h-5" />
            <span>Back to Home</span>
          </button>

          <h1 className="text-3xl font-bold text-white mb-4">Analyzing Wallet</h1>
          <div className="bg-gray-800/50 rounded-lg p-4 border border-gray-700">
            <div className="text-sm text-gray-400 mb-1">Wallet Address:</div>
            <div className="font-mono text-purple-400 break-all">{walletAddress}</div>
          </div>
        </motion.div>

        {/* Analysis Progress */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-gray-800/50 rounded-xl p-8 border border-gray-700"
        >
          <div className="flex items-center justify-center mb-8">
            <LoadingSpinner size="large" />
          </div>

          <div className="space-y-6">
            {analysisSteps.map((step, index) => (
              <motion.div
                key={step.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
                className="flex items-center space-x-4"
              >
                {/* Step Status Icon */}
                <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 ${
                  step.status === 'completed'
                    ? 'bg-green-500 border-green-500'
                    : step.status === 'processing'
                    ? 'bg-purple-500 border-purple-500 animate-pulse'
                    : 'bg-gray-700 border-gray-600'
                }`}>
                  {step.status === 'completed' ? (
                    <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                  ) : step.status === 'processing' ? (
                    <div className="w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  ) : (
                    <span className="text-gray-400 text-sm">{step.id}</span>
                  )}
                </div>

                {/* Step Content */}
                <div className="flex-1">
                  <div className={`font-medium ${
                    step.status === 'completed'
                      ? 'text-green-400'
                      : step.status === 'processing'
                      ? 'text-purple-400'
                      : 'text-gray-400'
                  }`}>
                    {step.name}
                  </div>
                  <div className="text-sm text-gray-500">
                    {step.description}
                  </div>
                </div>

                {/* Loading indicator for current step */}
                {step.status === 'processing' && (
                  <div className="flex space-x-1">
                    <div className="w-1 h-1 bg-purple-400 rounded-full animate-bounce"></div>
                    <div className="w-1 h-1 bg-purple-400 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
                    <div className="w-1 h-1 bg-purple-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
                  </div>
                )}
              </motion.div>
            ))}
          </div>

          {/* Progress Bar */}
          <div className="mt-8">
            <div className="flex justify-between text-sm text-gray-400 mb-2">
              <span>Progress</span>
              <span>{Math.round(((currentStep + 1) / analysisSteps.length) * 100)}%</span>
            </div>
            <div className="w-full bg-gray-700 rounded-full h-2">
              <div
                className="bg-gradient-to-r from-purple-500 to-pink-500 h-2 rounded-full transition-all duration-500"
                style={{ width: `${((currentStep + 1) / analysisSteps.length) * 100}%` }}
              ></div>
            </div>
          </div>

          {/* Estimated Time */}
          <div className="mt-6 text-center">
            <div className="text-sm text-gray-400">
              Estimated time remaining: ~{Math.max(0, (analysisSteps.length - currentStep - 1) * 2)} seconds
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default AnalysisPage;
