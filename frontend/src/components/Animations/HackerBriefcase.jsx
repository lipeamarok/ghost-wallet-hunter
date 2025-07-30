import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const HackerBriefcase = ({ isAnimating }) => {
  return (
    <motion.div
      className="relative inline-flex items-center justify-center"
      initial={{ scale: 1 }}
      animate={{
        scale: isAnimating ? [1, 1.1, 1] : 1,
        rotateY: isAnimating ? [0, 180, 360] : 0
      }}
      transition={{
        duration: 0.8,
        ease: "easeInOut",
        times: [0, 0.5, 1]
      }}
    >
      {/* Briefcase Base */}
      <div className="relative">
        <motion.div
          className="w-8 h-6 bg-gray-700 border-2 border-cyan-400 rounded-sm relative"
          animate={{
            borderColor: isAnimating ? ['#22d3ee', '#10b981', '#f59e0b', '#ef4444', '#22d3ee'] : '#22d3ee'
          }}
          transition={{ duration: 0.8, ease: "linear" }}
        >
          {/* Handle */}
          <div className="absolute -top-1 left-1/2 transform -translate-x-1/2 w-3 h-1 border border-cyan-400 rounded-t"></div>

          {/* Lock */}
          <div className="absolute top-1 left-1/2 transform -translate-x-1/2 w-1 h-1 bg-cyan-400 rounded-full"></div>

          {/* Digital Matrix Effect */}
          <AnimatePresence>
            {isAnimating && (
              <>
                {[...Array(6)].map((_, i) => (
                  <motion.div
                    key={i}
                    className="absolute text-green-400 text-xs font-mono"
                    style={{
                      left: `${10 + i * 8}%`,
                      top: `${20 + (i % 2) * 40}%`,
                    }}
                    initial={{ opacity: 0, scale: 0 }}
                    animate={{
                      opacity: [0, 1, 0],
                      scale: [0, 1, 0],
                      y: [0, -10, -20]
                    }}
                    transition={{
                      duration: 0.6,
                      delay: i * 0.1,
                      ease: "easeOut"
                    }}
                    exit={{ opacity: 0 }}
                  >
                    {Math.random() > 0.5 ? '1' : '0'}
                  </motion.div>
                ))}

                {/* Scanning Lines */}
                <motion.div
                  className="absolute inset-0 border-l-2 border-green-400"
                  initial={{ x: -8 }}
                  animate={{ x: 32 }}
                  transition={{ duration: 0.4, delay: 0.2 }}
                />

                {/* Success Glow */}
                <motion.div
                  className="absolute inset-0 bg-green-400 rounded-sm"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: [0, 0.3, 0] }}
                  transition={{ duration: 0.3, delay: 0.5 }}
                />
              </>
            )}
          </AnimatePresence>
        </motion.div>

        {/* Opening Animation */}
        <AnimatePresence>
          {isAnimating && (
            <motion.div
              className="absolute top-0 left-0 w-full h-3 bg-gray-600 border-2 border-cyan-400 rounded-t-sm origin-bottom"
              initial={{ rotateX: 0 }}
              animate={{ rotateX: -120 }}
              transition={{ duration: 0.4, delay: 0.6 }}
              style={{ transformStyle: "preserve-3d" }}
            >
              {/* Inner briefcase glow */}
              <div className="absolute inset-0 bg-gradient-to-t from-cyan-400/50 to-transparent"></div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </motion.div>
  );
};

export default HackerBriefcase;
