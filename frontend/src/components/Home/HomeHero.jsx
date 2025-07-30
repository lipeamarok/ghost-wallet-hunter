import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

export default function HomeHero() {
  const [currentTextIndex, setCurrentTextIndex] = useState(0);
  const [logoAnim, setLogoAnim] = useState(true); // animação contínua
  const [isHovered, setIsHovered] = useState(false);
  const [isReturning, setIsReturning] = useState(false);
  const hoverTimeout = useRef(null);
  const returnTimeout = useRef(null);

  const rotatingTexts = [
    "Find out if a Solana wallet is safe or suspicious in seconds.",
    "Automatic forensics, cluster detection, scam tracing.",
    "Transparent. No sign-up needed."
  ];

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTextIndex((prev) => (prev + 1) % rotatingTexts.length);
    }, 3000); // Muda a cada 3 segundos

    return () => clearInterval(interval);
  }, []);

  return (
    <motion.div
      initial={{ opacity: 0, y: -30 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.8 }}
      className="text-center space-y-8"
    >
      {/* Logo e Ghost Detective - À esquerda do texto */}
      <motion.div
        className="flex items-center justify-center space-x-0"
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.2, duration: 0.6 }}
      >
        <motion.img
          src="/logo.png"
          alt="Ghost Detective Logo"
          className="w-24 h-24 sm:w-26 sm:h-26 object-contain rounded-full shadow-lg -ml-20"
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
              // Após a animação de retorno, reativa o loop
              returnTimeout.current = setTimeout(() => {
                setIsReturning(false);
                setLogoAnim(true);
              }, 1500); // igual ao duration do retorno
            }, 5000);
          }}
          draggable={false}
          style={{ filter: 'drop-shadow(0 0 14px #3b82f688)' }}
        />
        <div className="text-left ml-[-0.5rem]">
          <h2 className="text-3xl font-bold text-white-ice drop-shadow-lg">
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
          <p className="text-base text-gray-400">AI-Powered Blockchain Forensics</p>
        </div>
      </motion.div>

      {/* Título principal com efeitos */}
      <motion.h1
        className="text-5xl font-bold tracking-tight text-white mb-8 drop-shadow-2xl"
        style={{
          textShadow: '0 0 20px rgba(59, 130, 246, 0.5), 0 0 40px rgba(59, 130, 246, 0.3)'
        }}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4, duration: 0.8 }}
      >
        Your AI Detectives for Solana
      </motion.h1>

      {/* Texto alternante simplificado */}
      <motion.div
        className="h-12 flex items-center justify-center"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.6, duration: 0.8 }}
      >
        <AnimatePresence mode="wait">
          <motion.div
            key={currentTextIndex}
            initial={{
              opacity: 0,
              y: 20
            }}
            animate={{
              opacity: 1,
              y: 0
            }}
            exit={{
              opacity: 0,
              y: -20
            }}
            transition={{
              duration: 0.5,
              ease: "easeInOut"
            }}
            className="flex items-center justify-center space-x-3 absolute"
          >
            <motion.span
              className={`text-xl ${
                currentTextIndex === 0 ? 'text-green-safe' :
                currentTextIndex === 1 ? 'text-blue-accent' :
                'text-purple-400'
              }`}
              animate={{
                scale: [1, 1.1, 1]
              }}
              transition={{
                duration: 1.5,
                repeat: Infinity,
                ease: "easeInOut"
              }}
            >
              ✓
            </motion.span>
            <p className="text-lg text-gray-300 text-center font-medium">
              {rotatingTexts[currentTextIndex]}
            </p>
          </motion.div>
        </AnimatePresence>
      </motion.div>
    </motion.div>
  );
}