import React, { useState, useRef } from 'react';
import { motion } from 'framer-motion';

export default function Header() {
  const [logoAnim, setLogoAnim] = useState(true);
  const [isHovered, setIsHovered] = useState(false);
  const [isReturning, setIsReturning] = useState(false);
  const hoverTimeout = useRef(null);
  const returnTimeout = useRef(null);

  return (
    <header
      className="fixed top-0 left-0 w-full z-50 bg-black/30 backdrop-blur-[1.5px]"
      // Blur fraquinho + preto transparente
      style={{
        WebkitBackdropFilter: 'blur(1.5px)',
        backdropFilter: 'blur(1.5px)'
      }}
    >
      {/* TAG BETA */}
      <div className="absolute top-2 left-2">
        <span className="bg-gradient-to-r from-purple-600 to-blue-500 text-white text-xs font-bold px-3 py-1 rounded-full shadow-sm tracking-widest border border-white/10 drop-shadow-lg select-none pointer-events-none" style={{ letterSpacing: "0.13em" }}>
          BETA
        </span>
      </div>

      <motion.div
        initial={{ opacity: 0, y: -30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8 }}
        className="mx-auto max-w-3xl pt-5 pb-2 px-2 sm:px-0"
      >
        <motion.div
          className="flex items-center justify-center space-x-0"
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ delay: 0.2, duration: 0.6 }}
        >
          <motion.img
            src="/logo.png"
            alt="Ghost Detective Logo"
            className="w-14 h-14 sm:w-16 sm:h-16 object-contain rounded-full shadow-lg -ml-12"
            animate={
              isHovered
                ? { scale: 4, rotate: 11 }
                : isReturning
                ? { scale: 1, rotate: 0 }
                : {
                    scale: logoAnim ? [1, 1.07, 0.97, 1.04, 1] : 1,
                    rotate: logoAnim ? [0, -3, 2, 0] : 0
                  }
            }
            transition={
              isHovered || isReturning
                ? { duration: 1.5, ease: "easeInOut" }
                : {
                    repeat: Infinity,
                    duration: 3.7,
                    repeatType: "loop",
                    ease: "easeInOut",
                    scale: { type: "tween", duration: 1.5, ease: "easeInOut" },
                    rotate: { type: "tween", duration: 1.5, ease: "easeInOut" }
                  }
            }
            onMouseEnter={() => {
              if (hoverTimeout.current) clearTimeout(hoverTimeout.current);
              if (returnTimeout.current) clearTimeout(returnTimeout.current);
              setIsHovered(true);
              setIsReturning(false);
              setLogoAnim(false);
            }}
            onMouseLeave={() => {
              hoverTimeout.current = setTimeout(() => {
                setIsHovered(false);
                setIsReturning(true);
                returnTimeout.current = setTimeout(() => {
                  setIsReturning(false);
                  setLogoAnim(true);
                }, 1500);
              }, 5000);
            }}
            draggable={false}
            style={{ filter: 'drop-shadow(0 0 14px #3b82f688)' }}
          />
          <div className="text-left ml-[-0.5rem]">
            <h2 className="text-2xl sm:text-3xl font-bold text-white-ice drop-shadow-lg">
              <style>
                {`
                  h2 {
                    -webkit-text-stroke: 0.01px #fff;
                    text-stroke: 0.01px #fff;
                  }
                `}
              </style>
              Ghost Wallet Hunter
            </h2>
            <p className="text-sm sm:text-base text-gray-400">
              AI-Powered Blockchain Forensics
            </p>
          </div>
        </motion.div>
      </motion.div>
    </header>
  );
}
