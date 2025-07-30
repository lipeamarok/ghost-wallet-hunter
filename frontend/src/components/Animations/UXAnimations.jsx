import React from 'react';
import { motion } from 'framer-motion';

const TerminalGlow = ({ children, isActive = false, glowColor = 'cyan' }) => {
  const glowColors = {
    cyan: '#22d3ee',
    green: '#10b981',
    red: '#ef4444',
    yellow: '#f59e0b',
    purple: '#a855f7'
  };

  return (
    <motion.div
      className="relative"
      animate={{
        filter: isActive
          ? [`drop-shadow(0 0 8px ${glowColors[glowColor]})`, `drop-shadow(0 0 12px ${glowColors[glowColor]})`, `drop-shadow(0 0 8px ${glowColors[glowColor]})`]
          : 'none'
      }}
      transition={{
        duration: 2,
        repeat: isActive ? Infinity : 0,
        ease: "easeInOut"
      }}
    >
      {children}

      {isActive && (
        <motion.div
          className="absolute inset-0 pointer-events-none"
          style={{
            border: `1px solid ${glowColors[glowColor]}`,
            borderRadius: 'inherit',
            opacity: 0.3
          }}
          animate={{
            scale: [1, 1.02, 1],
            opacity: [0.3, 0.6, 0.3]
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
      )}
    </motion.div>
  );
};

const TypewriterText = ({ text, speed = 50, delay = 0, className = "" }) => {
  return (
    <motion.span
      className={className}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ delay }}
    >
      {text.split('').map((char, index) => (
        <motion.span
          key={index}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{
            delay: delay + (index * speed / 1000),
            duration: 0.1
          }}
        >
          {char}
        </motion.span>
      ))}
    </motion.span>
  );
};

const ScanLine = ({ isActive = false, direction = 'horizontal' }) => {
  if (!isActive) return null;

  return (
    <motion.div
      className={`absolute ${direction === 'horizontal' ? 'left-0 right-0 h-0.5' : 'top-0 bottom-0 w-0.5'} bg-gradient-to-${direction === 'horizontal' ? 'r' : 'b'} from-transparent via-cyan-400 to-transparent pointer-events-none`}
      initial={{
        [direction === 'horizontal' ? 'top' : 'left']: '0%',
        opacity: 0
      }}
      animate={{
        [direction === 'horizontal' ? 'top' : 'left']: '100%',
        opacity: [0, 1, 0]
      }}
      transition={{
        duration: 2,
        repeat: Infinity,
        ease: "linear"
      }}
    />
  );
};

const DataFlowIndicator = ({ isActive = false, count = 3, color = 'green' }) => {
  const colorClasses = {
    green: 'bg-green-400',
    cyan: 'bg-cyan-400',
    yellow: 'bg-yellow-400',
    red: 'bg-red-400'
  };

  if (!isActive) return null;

  return (
    <div className="absolute top-0 right-0 flex space-x-1">
      {Array.from({ length: count }).map((_, i) => (
        <motion.div
          key={i}
          className={`w-2 h-2 rounded-full ${colorClasses[color]}`}
          initial={{ scale: 0, opacity: 0 }}
          animate={{
            scale: [0, 1, 0],
            opacity: [0, 1, 0],
            y: [0, -20, -40]
          }}
          transition={{
            duration: 1.5,
            delay: i * 0.2,
            repeat: Infinity,
            repeatDelay: 1
          }}
        />
      ))}
    </div>
  );
};

const LoadingDots = ({ isActive = false, dotCount = 3 }) => {
  if (!isActive) return null;

  return (
    <span className="inline-flex space-x-1">
      {Array.from({ length: dotCount }).map((_, i) => (
        <motion.span
          key={i}
          className="w-1 h-1 bg-current rounded-full"
          animate={{
            scale: [1, 1.5, 1],
            opacity: [0.3, 1, 0.3]
          }}
          transition={{
            duration: 0.8,
            delay: i * 0.2,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
      ))}
    </span>
  );
};

export {
  TerminalGlow,
  TypewriterText,
  ScanLine,
  DataFlowIndicator,
  LoadingDots
};
