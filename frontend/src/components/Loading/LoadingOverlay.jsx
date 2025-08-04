// src/components/Loading/LoadingOverlay.jsx
import React from 'react';
import { motion } from 'framer-motion';

export default function LoadingOverlay({ status }) {
  return (
    <motion.div
      className="fixed inset-0 z-[70] flex flex-col items-center justify-center pointer-events-none"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4 }}
    >
      <motion.h2
        className="text-2xl sm:text-3xl font-bold text-white mb-6"
        initial={{ y: 30, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1, duration: 0.7 }}
      >
        🕵️‍♂️ Detective Poirot is investigating...
      </motion.h2>
      <motion.div
        className="text-lg text-blue-accent font-mono bg-black/60 px-4 py-2 rounded shadow-lg"
        initial={{ y: 15, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.25, duration: 0.6 }}
      >
        {status || "Analyzing the blockchain universe..."}
      </motion.div>
      <motion.div
        className="mt-6 text-xs text-gray-400"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.7, duration: 0.5 }}
      >
        Loading, please wait
      </motion.div>
    </motion.div>
  );
}
