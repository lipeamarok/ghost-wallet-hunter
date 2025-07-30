import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const NetworkPulse = ({ isActive, connections = 0, delay = 0 }) => {
  const [pulseIndex, setPulseIndex] = useState(0);
  const [activePulses, setActivePulses] = useState([]);

  useEffect(() => {
    if (!isActive) return;

    const interval = setInterval(() => {
      setActivePulses(prev => {
        const newPulse = {
          id: Date.now() + Math.random(),
          startTime: Date.now(),
        };

        // Keep only recent pulses (last 3 seconds)
        const filtered = prev.filter(pulse => Date.now() - pulse.startTime < 3000);
        return [...filtered, newPulse];
      });
    }, 800 + Math.random() * 400); // Random interval between pulses

    return () => clearInterval(interval);
  }, [isActive]);

  if (!isActive) return null;

  return (
    <div className="absolute inset-0 pointer-events-none">
      <AnimatePresence>
        {activePulses.map((pulse) => (
          <motion.div
            key={pulse.id}
            className="absolute inset-0"
            initial={{ scale: 0, opacity: 1 }}
            animate={{
              scale: [0, 1.5, 2.5],
              opacity: [1, 0.6, 0]
            }}
            exit={{ opacity: 0 }}
            transition={{
              duration: 2.5,
              delay: delay / 1000,
              ease: "easeOut"
            }}
          >
            <div className="absolute inset-0 border-2 border-cyan-400 rounded-lg opacity-30" />
          </motion.div>
        ))}
      </AnimatePresence>

      {/* Data flow indicators */}
      <div className="absolute -top-1 -right-1">
        <AnimatePresence>
          {Array.from({ length: Math.min(connections, 3) }).map((_, i) => (
            <motion.div
              key={`flow-${i}`}
              className="absolute w-2 h-2 bg-green-400 rounded-full"
              initial={{
                scale: 0,
                x: 0,
                y: 0,
                opacity: 0
              }}
              animate={{
                scale: [0, 1, 0],
                x: [0, 20 + i * 10, 40 + i * 15],
                y: [0, -10 - i * 5, -20 - i * 8],
                opacity: [0, 1, 0]
              }}
              transition={{
                duration: 1.5,
                delay: delay / 1000 + i * 0.2,
                repeat: Infinity,
                repeatDelay: 2 + Math.random() * 2,
                ease: "easeInOut"
              }}
            />
          ))}
        </AnimatePresence>
      </div>

      {/* Signal strength indicator */}
      <motion.div
        className="absolute -bottom-2 left-1/2 transform -translate-x-1/2"
        initial={{ opacity: 0 }}
        animate={{
          opacity: [0, 1, 0.7, 1],
          scale: [0.8, 1, 0.9, 1]
        }}
        transition={{
          duration: 2,
          delay: delay / 1000,
          repeat: Infinity,
          ease: "easeInOut"
        }}
      >
        <div className="flex space-x-1">
          {Array.from({ length: 4 }).map((_, i) => (
            <motion.div
              key={i}
              className="w-1 bg-green-400"
              style={{ height: `${(i + 1) * 3}px` }}
              animate={{
                opacity: [0.3, 1, 0.3],
                backgroundColor: [
                  'rgba(34, 197, 94, 0.3)',
                  'rgba(34, 197, 94, 1)',
                  'rgba(34, 197, 94, 0.3)'
                ]
              }}
              transition={{
                duration: 1,
                delay: delay / 1000 + i * 0.1,
                repeat: Infinity,
                ease: "easeInOut"
              }}
            />
          ))}
        </div>
      </motion.div>
    </div>
  );
};

export default NetworkPulse;
